import '../../../core/database/row_reader.dart';
import '../../checkout/domain/payment.dart';

PaymentMethod _parseMethod(String value) => PaymentMethod.values.firstWhere(
  (m) => m.name == value,
  orElse: () => PaymentMethod.cash,
);

String _date(DateTime d) => DateTime(d.year, d.month, d.day).toIso8601String();

class ExpenseCategory {
  const ExpenseCategory({
    required this.id,
    required this.name,
    required this.color,
    this.monthlyBudgetCents = 0,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String id;
  final String name;

  /// ARGB color value.
  final int color;

  /// 0 = no budget.
  final int monthlyBudgetCents;
  final bool isActive;
  final int sortOrder;

  bool get hasBudget => monthlyBudgetCents > 0;

  ExpenseCategory copyWith({
    String? name,
    int? color,
    int? monthlyBudgetCents,
    bool? isActive,
  }) {
    return ExpenseCategory(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      monthlyBudgetCents: monthlyBudgetCents ?? this.monthlyBudgetCents,
      isActive: isActive ?? this.isActive,
      sortOrder: sortOrder,
    );
  }

  factory ExpenseCategory.fromMap(Map<String, Object?> map) => ExpenseCategory(
    id: map.stringOf('id'),
    name: map.stringOf('name'),
    color: map.intOf('color'),
    monthlyBudgetCents: map.intOf('monthly_budget_cents'),
    isActive: map.boolOf('is_active', true),
    sortOrder: map.intOf('sort_order'),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name.trim(),
    'color': color,
    'monthly_budget_cents': monthlyBudgetCents,
    'is_active': isActive ? 1 : 0,
    'sort_order': sortOrder,
  };
}

class Expense {
  const Expense({
    required this.id,
    required this.categoryId,
    required this.amountCents,
    required this.paymentMethod,
    required this.expenseDate,
    required this.createdAt,
    this.taxCents = 0,
    this.vendor,
    this.referenceNo,
    this.note,
    this.attachmentPath,
    this.recurringId,
  });

  final String id;
  final String categoryId;

  /// Total paid, tax included.
  final int amountCents;

  /// Tax portion of [amountCents] (input tax), informational.
  final int taxCents;
  final PaymentMethod paymentMethod;
  final String? vendor;
  final String? referenceNo;
  final String? note;
  final String? attachmentPath;

  /// Date the expense applies to (no time component).
  final DateTime expenseDate;
  final DateTime createdAt;
  final String? recurringId;

  Expense copyWith({
    String? categoryId,
    int? amountCents,
    int? taxCents,
    PaymentMethod? paymentMethod,
    String? vendor,
    String? referenceNo,
    String? note,
    String? attachmentPath,
    bool clearAttachment = false,
    DateTime? expenseDate,
  }) {
    return Expense(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      taxCents: taxCents ?? this.taxCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      vendor: vendor ?? this.vendor,
      referenceNo: referenceNo ?? this.referenceNo,
      note: note ?? this.note,
      attachmentPath: clearAttachment
          ? null
          : attachmentPath ?? this.attachmentPath,
      expenseDate: expenseDate ?? this.expenseDate,
      createdAt: createdAt,
      recurringId: recurringId,
    );
  }

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map.stringOf('id'),
    categoryId: map.stringOf('category_id'),
    amountCents: map.intOf('amount_cents'),
    taxCents: map.intOf('tax_cents'),
    paymentMethod: _parseMethod(map.stringOf('payment_method')),
    vendor: map.stringOrNull('vendor'),
    referenceNo: map.stringOrNull('reference_no'),
    note: map.stringOrNull('note'),
    attachmentPath: map.stringOrNull('attachment_path'),
    expenseDate: map.dateOf('expense_date'),
    createdAt: map.dateOf('created_at'),
    recurringId: map.stringOrNull('recurring_id'),
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'category_id': categoryId,
    'amount_cents': amountCents,
    'tax_cents': taxCents,
    'payment_method': paymentMethod.name,
    'vendor': _blankToNull(vendor),
    'reference_no': _blankToNull(referenceNo),
    'note': _blankToNull(note),
    'attachment_path': attachmentPath,
    'expense_date': _date(expenseDate),
    'created_at': createdAt.toIso8601String(),
    'recurring_id': recurringId,
  };
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

enum RecurrenceFrequency {
  weekly('Weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  yearly('Yearly');

  const RecurrenceFrequency(this.label);

  final String label;

  /// Next occurrence after [date]. Month-based steps keep the day of month,
  /// clamped to the month's length (31 Jan -> 28/29 Feb -> 31 Mar uses the
  /// clamped day, so pick days <= 28 for strict regularity).
  DateTime next(DateTime date) {
    DateTime addMonths(int months) {
      final firstOfTarget = DateTime(date.year, date.month + months);
      final lastDay = DateTime(
        firstOfTarget.year,
        firstOfTarget.month + 1,
        0,
      ).day;
      return DateTime(
        firstOfTarget.year,
        firstOfTarget.month,
        date.day > lastDay ? lastDay : date.day,
      );
    }

    return switch (this) {
      RecurrenceFrequency.weekly => DateTime(
        date.year,
        date.month,
        date.day + 7,
      ),
      RecurrenceFrequency.monthly => addMonths(1),
      RecurrenceFrequency.quarterly => addMonths(3),
      RecurrenceFrequency.yearly => addMonths(12),
    };
  }

  static RecurrenceFrequency parse(String value) =>
      RecurrenceFrequency.values.firstWhere(
        (f) => f.name == value,
        orElse: () => RecurrenceFrequency.monthly,
      );
}

/// Template that automatically creates an [Expense] on each due date.
class RecurringExpense {
  const RecurringExpense({
    required this.id,
    required this.categoryId,
    required this.amountCents,
    required this.paymentMethod,
    required this.frequency,
    required this.nextDueDate,
    required this.createdAt,
    this.vendor,
    this.note,
    this.isActive = true,
  });

  final String id;
  final String categoryId;
  final int amountCents;
  final PaymentMethod paymentMethod;
  final RecurrenceFrequency frequency;
  final DateTime nextDueDate;
  final DateTime createdAt;
  final String? vendor;
  final String? note;
  final bool isActive;

  RecurringExpense copyWith({
    String? categoryId,
    int? amountCents,
    PaymentMethod? paymentMethod,
    RecurrenceFrequency? frequency,
    DateTime? nextDueDate,
    String? vendor,
    String? note,
    bool? isActive,
  }) {
    return RecurringExpense(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      amountCents: amountCents ?? this.amountCents,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      frequency: frequency ?? this.frequency,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      createdAt: createdAt,
      vendor: vendor ?? this.vendor,
      note: note ?? this.note,
      isActive: isActive ?? this.isActive,
    );
  }

  factory RecurringExpense.fromMap(Map<String, Object?> map) =>
      RecurringExpense(
        id: map.stringOf('id'),
        categoryId: map.stringOf('category_id'),
        amountCents: map.intOf('amount_cents'),
        paymentMethod: _parseMethod(map.stringOf('payment_method')),
        frequency: RecurrenceFrequency.parse(map.stringOf('frequency')),
        nextDueDate: map.dateOf('next_due_date'),
        createdAt: map.dateOf('created_at'),
        vendor: map.stringOrNull('vendor'),
        note: map.stringOrNull('note'),
        isActive: map.boolOf('is_active', true),
      );

  Map<String, Object?> toMap() => {
    'id': id,
    'category_id': categoryId,
    'amount_cents': amountCents,
    'payment_method': paymentMethod.name,
    'frequency': frequency.name,
    'next_due_date': _date(nextDueDate),
    'created_at': createdAt.toIso8601String(),
    'vendor': _blankToNull(vendor),
    'note': _blankToNull(note),
    'is_active': isActive ? 1 : 0,
  };
}

/// Spend in one category over a period, with its monthly budget scaled to
/// the period length.
class CategorySpend {
  const CategorySpend({
    required this.category,
    required this.spentCents,
    required this.budgetCents,
  });

  final ExpenseCategory category;
  final int spentCents;
  final int budgetCents;

  double get budgetUsage => budgetCents <= 0 ? 0 : spentCents / budgetCents;
  bool get isOverBudget => budgetCents > 0 && spentCents > budgetCents;
}
