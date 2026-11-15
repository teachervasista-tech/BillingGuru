import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../../app/widgets/period_dropdown.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/currency/currency_provider.dart';
import '../../../../core/export/csv_export.dart';
import '../../../../core/period/date_range.dart';
import '../../../../core/storage/open_file.dart';
import '../../domain/expense.dart';
import '../expense_providers.dart';
import '../widgets/category_spend_card.dart';
import '../widgets/expense_form_dialog.dart';
import '../widgets/recurring_expenses_dialog.dart';

class ExpensesScreen extends ConsumerStatefulWidget {
  const ExpensesScreen({super.key});

  @override
  ConsumerState<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends ConsumerState<ExpensesScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _export(ExpensesState state) async {
    final messenger = ScaffoldMessenger.of(context);
    final path = await CsvExport.save(
      suggestedName:
          'expenses-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      rows: [
        [
          'Date',
          'Category',
          'Amount',
          'Tax',
          'Paid by',
          'Vendor',
          'Reference',
          'Note',
        ],
        for (final e in state.expenses)
          [
            DateFormat('yyyy-MM-dd').format(e.expenseDate),
            state.categoryById(e.categoryId)?.name ?? '',
            CsvExport.amount(e.amountCents),
            CsvExport.amount(e.taxCents),
            e.paymentMethod.label,
            e.vendor,
            e.referenceNo,
            e.note,
          ],
      ],
    );
    if (path != null) {
      messenger.showSnackBar(SnackBar(content: Text('Exported to $path')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(expensesViewModelProvider);
    final viewModel = ref.read(expensesViewModelProvider.notifier);
    final currency = ref.watch(currencyProvider);

    ref.listen(expensesViewModelProvider, (previous, next) {
      final created = next.value?.recurringCreated ?? 0;
      if (created > 0 && previous?.value?.recurringCreated != created) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$created recurring expense${created == 1 ? '' : 's'} added.',
            ),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses'),
        actions: [
          IconButton(
            tooltip: 'Recurring expenses',
            icon: const Icon(Icons.repeat),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const RecurringExpensesDialog(),
            ),
          ),
          IconButton(
            tooltip: 'Export to CSV',
            icon: const Icon(Icons.download_outlined),
            onPressed: asyncState.value == null
                ? null
                : () => _export(asyncState.value!),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: viewModel.refresh,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showExpenseFormDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Add expense'),
      ),
      bottomNavigationBar: const CopyrightBanner(),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      labelText: 'Search expenses',
                      hintText: 'Vendor, note or reference',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          viewModel.search('');
                        },
                      ),
                    ),
                    onChanged: viewModel.search,
                  ),
                ),
                const SizedBox(width: 16),
                PeriodDropdown(
                  selected: asyncState.value?.period ?? PeriodPreset.month,
                  onChanged: viewModel.setPeriod,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: asyncState.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Unable to load expenses:\n$error'),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: () =>
                            ref.invalidate(expensesViewModelProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (state) => Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _ExpenseList(state: state)),
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 340,
                      child: ListView(
                        children: [
                          _TotalCard(
                            label: state.categoryId == null
                                ? 'Total spent'
                                : 'Spent on '
                                      '${state.categoryById(state.categoryId!)?.name ?? ''}',
                            amount: CurrencyFormatter.formatCents(
                              state.totalCents,
                              currency: currency,
                            ),
                            count: state.expenses.length,
                            overBudget: state.overBudgetCount,
                          ),
                          const SizedBox(height: 12),
                          CategorySpendCard(
                            spend: state.spend,
                            selectedCategoryId: state.categoryId,
                            onCategoryTap: (id) => viewModel.setCategory(
                              state.categoryId == id ? null : id,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({
    required this.label,
    required this.amount,
    required this.count,
    required this.overBudget,
  });

  final String label;
  final String amount;
  final int count;
  final int overBudget;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            const SizedBox(height: 4),
            Text(
              amount,
              key: const Key('expensesTotal'),
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '$count expense${count == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall,
            ),
            if (overBudget > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$overBudget categor${overBudget == 1 ? 'y' : 'ies'} '
                    'over budget',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpenseList extends ConsumerWidget {
  const _ExpenseList({required this.state});

  final ExpensesState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 56,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text('No expenses for this period.'),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.expenses.length,
      itemBuilder: (context, index) {
        final expense = state.expenses[index];
        return ExpenseTile(
          expense: expense,
          category: state.categoryById(expense.categoryId),
        );
      },
    );
  }
}

class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({required this.expense, this.category, super.key});

  final Expense expense;
  final ExpenseCategory? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final color = Color(category?.color ?? 0xFF9E9E9E);
    final details = [
      DateFormat.yMMMd().format(expense.expenseDate),
      category?.name ?? 'Unknown',
      expense.paymentMethod.label,
      if (expense.referenceNo != null) '#${expense.referenceNo}',
    ].join(' · ');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: () => showExpenseFormDialog(context, expense: expense),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.18),
          foregroundColor: color,
          child: Icon(
            expense.recurringId != null ? Icons.repeat : Icons.receipt_long,
          ),
        ),
        title: Text(
          expense.vendor ?? category?.name ?? 'Expense',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          expense.note == null ? details : '$details\n${expense.note}',
        ),
        isThreeLine: expense.note != null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatCents(
                expense.amountCents,
                currency: currency,
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (expense.attachmentPath != null)
              IconButton(
                tooltip: 'Open receipt',
                icon: const Icon(Icons.attach_file),
                onPressed: () => openWithSystem(expense.attachmentPath!),
              ),
            IconButton(
              tooltip: 'Delete expense',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete expense'),
                    content: const Text('This cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref
                      .read(expensesViewModelProvider.notifier)
                      .deleteExpense(expense);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
