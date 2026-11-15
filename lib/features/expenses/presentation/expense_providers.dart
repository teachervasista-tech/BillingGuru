import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../../../core/period/date_range.dart';
import '../../../core/settings/app_settings_provider.dart';
import '../../../core/storage/app_file_storage.dart';
import '../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../reports/presentation/providers/report_providers.dart';
import '../data/expense_local_service.dart';
import '../domain/expense.dart';

final expenseServiceProvider = Provider<ExpenseLocalService>((ref) {
  return ExpenseLocalService(database: ref.watch(appDatabaseProvider));
});

/// All categories (active and archived), in display order.
final expenseCategoriesProvider = FutureProvider<List<ExpenseCategory>>((ref) {
  return ref.watch(expenseServiceProvider).getCategories();
});

final recurringExpensesProvider = FutureProvider<List<RecurringExpense>>((ref) {
  return ref.watch(expenseServiceProvider).getRecurring();
});

/// Refreshes everything derived from expenses (lists, reports, dashboard).
void invalidateExpenseData(Ref ref) {
  ref.invalidate(expensesViewModelProvider);
  ref.invalidate(expenseCategoriesProvider);
  ref.invalidate(recurringExpensesProvider);
  ref.invalidate(reportProvider);
  ref.invalidate(dashboardViewModelProvider);
}

class ExpensesState {
  const ExpensesState({
    this.expenses = const [],
    this.categories = const [],
    this.spend = const [],
    this.period = PeriodPreset.month,
    this.categoryId,
    this.search = '',
    this.recurringCreated = 0,
  });

  final List<Expense> expenses;
  final List<ExpenseCategory> categories;
  final List<CategorySpend> spend;
  final PeriodPreset period;
  final String? categoryId;
  final String search;

  /// Expenses auto-created from recurring templates on this load.
  final int recurringCreated;

  int get totalCents => expenses.fold(0, (sum, e) => sum + e.amountCents);

  ExpenseCategory? categoryById(String id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  int get overBudgetCount => spend.where((s) => s.isOverBudget).length;
}

final expensesViewModelProvider =
    AsyncNotifierProvider<ExpensesViewModel, ExpensesState>(
      ExpensesViewModel.new,
    );

class ExpensesViewModel extends AsyncNotifier<ExpensesState> {
  ExpenseLocalService get _service => ref.read(expenseServiceProvider);

  @override
  Future<ExpensesState> build() async {
    final created = await _service.materializeDueRecurring(DateTime.now());
    return _load(const ExpensesState(), recurringCreated: created);
  }

  Future<ExpensesState> _load(
    ExpensesState filters, {
    int recurringCreated = 0,
  }) async {
    final fyStart = ref.read(appSettingsProvider).financialYearStartMonth;
    final range = filters.period.rangeFor(
      DateTime.now(),
      financialYearStartMonth: fyStart,
    );
    final results = await Future.wait([
      _service.getExpenses(
        range: range,
        categoryId: filters.categoryId,
        search: filters.search,
      ),
      _service.getCategories(),
      _service.spendByCategory(range),
    ]);
    return ExpensesState(
      expenses: results[0] as List<Expense>,
      categories: results[1] as List<ExpenseCategory>,
      spend: results[2] as List<CategorySpend>,
      period: filters.period,
      categoryId: filters.categoryId,
      search: filters.search,
      recurringCreated: recurringCreated,
    );
  }

  ExpensesState get _current => state.value ?? const ExpensesState();

  Future<void> _reload(ExpensesState filters) async {
    state = await AsyncValue.guard(() => _load(filters));
  }

  Future<void> setPeriod(PeriodPreset period) => _reload(
    ExpensesState(
      period: period,
      categoryId: _current.categoryId,
      search: _current.search,
    ),
  );

  Future<void> setCategory(String? categoryId) => _reload(
    ExpensesState(
      period: _current.period,
      categoryId: categoryId,
      search: _current.search,
    ),
  );

  Future<void> search(String text) => _reload(
    ExpensesState(
      period: _current.period,
      categoryId: _current.categoryId,
      search: text,
    ),
  );

  Future<void> refresh() => _reload(_current);

  Future<void> _afterMutation() async {
    ref.invalidate(reportProvider);
    ref.invalidate(dashboardViewModelProvider);
    ref.invalidate(expenseCategoriesProvider);
    ref.invalidate(recurringExpensesProvider);
    await refresh();
  }

  Future<void> saveExpense(Expense expense) async {
    await _service.saveExpense(expense);
    await _afterMutation();
  }

  Future<void> deleteExpense(Expense expense) async {
    await _service.deleteExpense(expense.id);
    await AppFileStorage.delete(expense.attachmentPath);
    await _afterMutation();
  }

  Future<void> saveCategory(ExpenseCategory category) async {
    await _service.saveCategory(category);
    await _afterMutation();
  }

  Future<void> addCategory(
    String name,
    int color, {
    int monthlyBudgetCents = 0,
  }) async {
    await _service.addCategory(
      name,
      color,
      monthlyBudgetCents: monthlyBudgetCents,
    );
    await _afterMutation();
  }

  Future<void> saveRecurring(RecurringExpense recurring) async {
    await _service.saveRecurring(recurring);
    final created = await _service.materializeDueRecurring(DateTime.now());
    await _afterMutation();
    if (created > 0) {
      state = state.whenData(
        (s) => ExpensesState(
          expenses: s.expenses,
          categories: s.categories,
          spend: s.spend,
          period: s.period,
          categoryId: s.categoryId,
          search: s.search,
          recurringCreated: created,
        ),
      );
    }
  }

  Future<void> deleteRecurring(String id) async {
    await _service.deleteRecurring(id);
    await _afterMutation();
  }

  String newId() => _service.newId();
}
