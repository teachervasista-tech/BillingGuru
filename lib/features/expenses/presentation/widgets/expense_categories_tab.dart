import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/category_edit_dialog.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/currency/currency_provider.dart';
import '../../domain/expense.dart';
import '../expense_providers.dart';

/// Settings → Expense categories: names, colors and monthly budgets.
class ExpenseCategoriesTab extends ConsumerWidget {
  const ExpenseCategoriesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(expenseCategoriesProvider);
    final currency = ref.watch(currencyProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Expense categories',
          description:
              'Set a monthly budget to track spending against it. Archived '
              'categories are hidden when adding expenses but keep history.',
          trailing: FilledButton.icon(
            onPressed: () => _edit(context, ref, null),
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
          ),
          child: categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Unable to load categories: $error'),
            data: (categories) => Column(
              children: [
                for (final category in categories)
                  ListTile(
                    leading: CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(category.color),
                    ),
                    title: Text(
                      category.name,
                      style: category.isActive
                          ? null
                          : const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                    ),
                    subtitle: Text(
                      category.hasBudget
                          ? 'Budget ${CurrencyFormatter.formatCents(category.monthlyBudgetCents, currency: currency)} / month'
                          : 'No budget',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Tooltip(
                          message: category.isActive ? 'Active' : 'Archived',
                          child: Switch(
                            value: category.isActive,
                            onChanged: (active) => ref
                                .read(expensesViewModelProvider.notifier)
                                .saveCategory(
                                  category.copyWith(isActive: active),
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, ref, category),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ExpenseCategory? category,
  ) async {
    final result = await showDialog<CategoryDraft>(
      context: context,
      builder: (_) => CategoryEditDialog(
        title: category == null ? 'Add category' : 'Edit category',
        name: category?.name ?? '',
        color: category?.color,
        showBudget: true,
        budgetCents: category?.monthlyBudgetCents ?? 0,
      ),
    );
    if (result == null) return;
    final viewModel = ref.read(expensesViewModelProvider.notifier);
    try {
      if (category == null) {
        await viewModel.addCategory(
          result.name,
          result.color,
          monthlyBudgetCents: result.budgetCents,
        );
      } else {
        await viewModel.saveCategory(
          category.copyWith(
            name: result.name,
            color: result.color,
            monthlyBudgetCents: result.budgetCents,
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save category: $error')),
        );
      }
    }
  }
}
