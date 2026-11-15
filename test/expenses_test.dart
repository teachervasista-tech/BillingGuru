import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/database/migrations.dart';
import 'package:billing_guru/core/period/date_range.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/expenses/data/expense_local_service.dart';
import 'package:billing_guru/features/expenses/domain/expense.dart';
import 'package:billing_guru/features/inventory/data/services/inventory_local_service.dart';
import 'package:billing_guru/features/reports/data/services/report_local_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

void main() {
  late AppDatabase database;
  late ExpenseLocalService expenses;

  setUp(() {
    database = createTestDatabase();
    expenses = ExpenseLocalService(database: database);
  });
  tearDown(() => database.close());

  Expense expense(
    String id,
    int cents,
    DateTime date, {
    String category = 'cat-rent',
    String? vendor,
  }) => Expense(
    id: id,
    categoryId: category,
    amountCents: cents,
    paymentMethod: PaymentMethod.cash,
    expenseDate: date,
    createdAt: date,
    vendor: vendor,
  );

  group('categories', () {
    test('default categories are seeded once', () async {
      final categories = await expenses.getCategories();
      expect(categories.map((c) => c.id), contains(stockPurchaseCategoryId));
      expect(categories.length, defaultExpenseCategories.length);
    });

    test('added category gets the next sort order and its budget', () async {
      final added = await expenses.addCategory(
        'Insurance',
        0xFF000000,
        monthlyBudgetCents: 5000,
      );
      final categories = await expenses.getCategories();
      expect(categories.last.id, added.id);
      expect(categories.last.monthlyBudgetCents, 5000);
    });
  });

  group('expenses', () {
    test('filters by range, category and search text', () async {
      await expenses.saveExpense(
        expense('a', 1000, DateTime(2026, 11, 2), vendor: 'Landlord'),
      );
      await expenses.saveExpense(
        expense(
          'b',
          250,
          DateTime(2026, 11, 10),
          category: 'cat-utilities',
          vendor: 'Power Co',
        ),
      );
      await expenses.saveExpense(expense('c', 999, DateTime(2026, 10, 31)));

      final november = DateRange(DateTime(2026, 11), DateTime(2026, 12));
      expect((await expenses.getExpenses(range: november)).map((e) => e.id), [
        'b',
        'a',
      ]);
      expect(
        (await expenses.getExpenses(
          range: november,
          categoryId: 'cat-utilities',
        )).single.id,
        'b',
      );
      expect((await expenses.getExpenses(search: 'land')).single.id, 'a');
      expect(await expenses.totalExpenses(november), 1250);
    });

    test('spend by category scales monthly budgets to the period', () async {
      final rent = (await expenses.getCategories()).firstWhere(
        (c) => c.id == 'cat-rent',
      );
      await expenses.saveCategory(rent.copyWith(monthlyBudgetCents: 10000));
      await expenses.saveExpense(expense('a', 12000, DateTime(2026, 11, 2)));

      final month = DateRange(DateTime(2026, 11), DateTime(2026, 12));
      final spend = await expenses.spendByCategory(month);
      final rentSpend = spend.firstWhere((s) => s.category.id == 'cat-rent');
      expect(rentSpend.spentCents, 12000);
      expect(rentSpend.budgetCents, 10000);
      expect(rentSpend.isOverBudget, isTrue);

      final quarter = DateRange(DateTime(2026, 10), DateTime(2027, 1));
      final quarterRent = (await expenses.spendByCategory(quarter))
          .firstWhere((s) => s.category.id == 'cat-rent');
      expect(quarterRent.budgetCents, 30000);
      expect(quarterRent.isOverBudget, isFalse);
    });
  });

  group('recurring', () {
    test('frequency keeps the day of month, clamped to month length', () {
      expect(
        RecurrenceFrequency.monthly.next(DateTime(2026, 1, 31)),
        DateTime(2026, 2, 28),
      );
      expect(
        RecurrenceFrequency.quarterly.next(DateTime(2026, 11, 15)),
        DateTime(2027, 2, 15),
      );
      expect(
        RecurrenceFrequency.weekly.next(DateTime(2026, 12, 29)),
        DateTime(2027, 1, 5),
      );
    });

    test(
      'materializes every missed occurrence and advances the template',
      () async {
        await expenses.saveRecurring(
          RecurringExpense(
            id: 'r1',
            categoryId: 'cat-rent',
            amountCents: 50000,
            paymentMethod: PaymentMethod.digital,
            frequency: RecurrenceFrequency.monthly,
            nextDueDate: DateTime(2026, 9, 1),
            createdAt: DateTime(2026, 8, 1),
            vendor: 'Landlord',
          ),
        );

        final created = await expenses.materializeDueRecurring(
          DateTime(2026, 11, 15, 9),
        );
        expect(created, 3); // Sep, Oct, Nov

        final all = await expenses.getExpenses();
        expect(all.map((e) => e.expenseDate), [
          DateTime(2026, 11, 1),
          DateTime(2026, 10, 1),
          DateTime(2026, 9, 1),
        ]);
        expect(all.every((e) => e.recurringId == 'r1'), isTrue);
        expect(
          (await expenses.getRecurring()).single.nextDueDate,
          DateTime(2026, 12, 1),
        );

        // Running again the same day creates nothing.
        expect(
          await expenses.materializeDueRecurring(DateTime(2026, 11, 15)),
          0,
        );
      },
    );

    test('paused templates are skipped', () async {
      await expenses.saveRecurring(
        RecurringExpense(
          id: 'r1',
          categoryId: 'cat-rent',
          amountCents: 100,
          paymentMethod: PaymentMethod.cash,
          frequency: RecurrenceFrequency.weekly,
          nextDueDate: DateTime(2026, 11, 1),
          createdAt: DateTime(2026, 11, 1),
          isActive: false,
        ),
      );
      expect(await expenses.materializeDueRecurring(DateTime(2026, 11, 15)), 0);
    });
  });

  group('receiving stock with cost', () {
    test('updates weighted-average cost and links a stock expense', () async {
      final inventory = InventoryLocalService(database: database);
      final db = await database.database;
      // Seed product Test-001 has 50 units and no cost price.
      await db.update('products', {
        'cost_price_cents': 100,
      }, where: "id = 'Test-001'");

      await inventory.increaseStock(
        productId: 'Test-001',
        quantity: 50,
        unitCostCents: 200,
        supplier: 'Beans Ltd',
        recordExpense: true,
        paymentMethod: PaymentMethod.card,
      );

      final product = (await db.query(
        'products',
        where: "id = 'Test-001'",
      )).single;
      expect(product['stock_quantity'], 100);
      expect(product['cost_price_cents'], 150); // (50*100 + 50*200) / 100

      final expense = (await expenses.getExpenses()).single;
      expect(expense.categoryId, stockPurchaseCategoryId);
      expect(expense.amountCents, 10000);
      expect(expense.vendor, 'Beans Ltd');
      expect(expense.paymentMethod, PaymentMethod.card);

      final movement = (await db.query(
        'stock_movements',
        where: "movement_type = 'purchase'",
      )).single;
      expect(movement['expense_id'], expense.id);
      expect(movement['unit_cost_cents'], 200);

      // Deleting the expense keeps the stock movement but unlinks it.
      await expenses.deleteExpense(expense.id);
      final unlinked = (await db.query(
        'stock_movements',
        where: "movement_type = 'purchase'",
      )).single;
      expect(unlinked['expense_id'], isNull);
    });

    test('without a cost, stock increases and cost is unchanged', () async {
      final inventory = InventoryLocalService(database: database);
      await inventory.increaseStock(productId: 'Test-001', quantity: 5);
      final db = await database.database;
      final product = (await db.query(
        'products',
        where: "id = 'Test-001'",
      )).single;
      expect(product['stock_quantity'], 55);
      expect(product['cost_price_cents'], 0);
      expect(await expenses.getExpenses(), isEmpty);
    });
  });

  test('profit & loss: COGS from sale-time cost; stock purchases are '
      'excluded from operating expenses', () async {
    final db = await database.database;
    final day = DateTime(2026, 11, 10, 12);
    await db.insert('sales', {
      'id': 's1',
      'invoice_number': 'INV-1',
      'subtotal_cents': 1000,
      'discount_cents': 0,
      'tax_cents': 100,
      'total_cents': 1100,
      'payment_method': 'cash',
      'created_at': day.toIso8601String(),
      'sync_status': 'pending',
    });
    await db.insert('sale_items', {
      'id': 'i1',
      'sale_id': 's1',
      'product_id': 'Test-001',
      'quantity': 4,
      'unit_price_cents': 200,
      'total_cents': 800,
      'unit_cost_cents': 120,
    });
    await db.insert('sale_items', {
      'id': 'i2',
      'sale_id': 's1',
      'product_id': 'Test-001',
      'quantity': 1,
      'unit_price_cents': 200,
      'total_cents': 200,
      'unit_cost_cents': 0,
    });
    await expenses.saveExpense(expense('rent', 300, day));
    await expenses.saveExpense(
      expense('stock', 5000, day, category: stockPurchaseCategoryId),
    );

    final pl = await ReportLocalService(database: database)
        .getProfitLoss(from: DateTime(2026, 11), to: DateTime(2026, 12));

    expect(pl.salesCents, 1100);
    expect(pl.netSalesCents, 1000);
    expect(pl.cogsCents, 480);
    expect(pl.grossProfitCents, 520);
    expect(pl.operatingExpensesCents, 300);
    expect(pl.netProfitCents, 220);
    expect(pl.stockPurchasesCents, 5000);
    expect(pl.cashFlowCents, 1100 - 300 - 5000);
    expect(pl.unitsWithoutCost, 1);
  });
}
