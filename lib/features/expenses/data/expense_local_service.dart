import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../../../core/period/date_range.dart';
import '../domain/expense.dart';

/// Number of months covered by [range]; whole calendar months are exact,
/// anything else is prorated by days.
double monthsIn(DateRange range) {
  final from = range.from;
  final to = range.to;
  if (from.day == 1 && to.day == 1 && from.hour == 0 && to.hour == 0) {
    return ((to.year - from.year) * 12 + to.month - from.month).toDouble();
  }
  return to.difference(from).inHours / 24 / (365.25 / 12);
}

class ExpenseLocalService {
  ExpenseLocalService({required this.database});

  final AppDatabase database;
  static const _uuid = Uuid();

  String newId() => _uuid.v4();

  // ---- Categories -------------------------------------------------------

  Future<List<ExpenseCategory>> getCategories({bool activeOnly = false}) async {
    final db = await database.database;
    final rows = await db.query(
      'expense_categories',
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'sort_order ASC, name COLLATE NOCASE ASC',
    );
    return rows.map(ExpenseCategory.fromMap).toList();
  }

  Future<void> saveCategory(ExpenseCategory category) async {
    final db = await database.database;
    await db.insert(
      'expense_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<ExpenseCategory> addCategory(
    String name,
    int color, {
    int monthlyBudgetCents = 0,
  }) async {
    final db = await database.database;
    final order = (await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next FROM expense_categories',
    )).first.intOf('next');
    final category = ExpenseCategory(
      id: newId(),
      name: name.trim(),
      color: color,
      monthlyBudgetCents: monthlyBudgetCents,
      sortOrder: order,
    );
    await db.insert(
      'expense_categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
    return category;
  }

  // ---- Expenses ---------------------------------------------------------

  Future<List<Expense>> getExpenses({
    DateRange? range,
    String? categoryId,
    String search = '',
  }) async {
    final db = await database.database;
    final conditions = <String>[];
    final args = <Object?>[];
    if (range != null) {
      conditions.add(DateRange.sqlClause('expense_date'));
      args.addAll(range.sqlArgs);
    }
    if (categoryId != null) {
      conditions.add('category_id = ?');
      args.add(categoryId);
    }
    final text = search.trim();
    if (text.isNotEmpty) {
      conditions.add('(vendor LIKE ? OR note LIKE ? OR reference_no LIKE ?)');
      args.addAll(['%$text%', '%$text%', '%$text%']);
    }
    final rows = await db.query(
      'expenses',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : args,
      orderBy: 'expense_date DESC, created_at DESC',
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<void> saveExpense(Expense expense) async {
    final db = await database.database;
    await db.insert(
      'expenses',
      expense.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteExpense(String id) async {
    final db = await database.database;
    await db.transaction((txn) async {
      // Keep the stock ledger intact but drop the link to the expense.
      await txn.update(
        'stock_movements',
        {'expense_id': null},
        where: 'expense_id = ?',
        whereArgs: [id],
      );
      await txn.delete('expenses', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<int> totalExpenses(DateRange range) async {
    final db = await database.database;
    final rows = await db.rawQuery(
      'SELECT COALESCE(SUM(amount_cents), 0) AS total FROM expenses '
      'WHERE ${DateRange.sqlClause('expense_date')}',
      range.sqlArgs,
    );
    return rows.first.intOf('total');
  }

  /// Spend per category in [range] (all categories that have spend or an
  /// active budget), with budgets scaled to the range length.
  Future<List<CategorySpend>> spendByCategory(DateRange? range) async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT c.*, COALESCE(SUM(e.amount_cents), 0) AS spent_cents
      FROM expense_categories c
      LEFT JOIN expenses e
        ON e.category_id = c.id
        ${range == null ? '' : 'AND ${DateRange.sqlClause('e.expense_date')}'}
      GROUP BY c.id
      ORDER BY spent_cents DESC, c.sort_order ASC
      ''', range?.sqlArgs ?? const []);
    final months = range == null ? 0.0 : monthsIn(range);

    return [
      for (final row in rows)
        if (row.intOf('spent_cents') > 0 ||
            (row.boolOf('is_active') && row.intOf('monthly_budget_cents') > 0))
          CategorySpend(
            category: ExpenseCategory.fromMap(row),
            spentCents: row.intOf('spent_cents'),
            budgetCents: (row.intOf('monthly_budget_cents') * months).round(),
          ),
    ];
  }

  // ---- Recurring --------------------------------------------------------

  Future<List<RecurringExpense>> getRecurring() async {
    final db = await database.database;
    final rows = await db.query(
      'recurring_expenses',
      orderBy: 'is_active DESC, next_due_date ASC',
    );
    return rows.map(RecurringExpense.fromMap).toList();
  }

  Future<void> saveRecurring(RecurringExpense recurring) async {
    final db = await database.database;
    await db.insert(
      'recurring_expenses',
      recurring.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteRecurring(String id) async {
    final db = await database.database;
    await db.delete('recurring_expenses', where: 'id = ?', whereArgs: [id]);
  }

  /// Creates an expense for every due occurrence up to and including
  /// [today] and advances each template. Returns the number created.
  Future<int> materializeDueRecurring(DateTime today) async {
    final db = await database.database;
    final todayDate = DateTime(today.year, today.month, today.day);
    var created = 0;

    await db.transaction((txn) async {
      final rows = await txn.query(
        'recurring_expenses',
        where: 'is_active = 1 AND next_due_date <= ?',
        whereArgs: [todayDate.toIso8601String()],
      );
      for (final template in rows.map(RecurringExpense.fromMap)) {
        var due = template.nextDueDate;
        while (!due.isAfter(todayDate)) {
          await txn.insert('expenses', {
            ...Expense(
              id: newId(),
              categoryId: template.categoryId,
              amountCents: template.amountCents,
              paymentMethod: template.paymentMethod,
              vendor: template.vendor,
              note: template.note,
              expenseDate: due,
              createdAt: DateTime.now(),
            ).toMap(),
            'recurring_id': template.id,
          });
          created++;
          due = template.frequency.next(due);
        }
        await txn.update(
          'recurring_expenses',
          {'next_due_date': due.toIso8601String()},
          where: 'id = ?',
          whereArgs: [template.id],
        );
      }
    });
    return created;
  }
}
