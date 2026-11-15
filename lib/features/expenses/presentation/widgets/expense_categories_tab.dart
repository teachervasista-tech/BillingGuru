import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/section_card.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/currency/currency_provider.dart';
import '../../../../core/currency/money_input.dart';
import '../../domain/expense.dart';
import '../expense_providers.dart';

const _palette = [
  0xFF5C6BC0,
  0xFF26A69A,
  0xFFEF6C00,
  0xFF8D6E63,
  0xFF29B6F6,
  0xFF78909C,
  0xFFEC407A,
  0xFF9E9E9E,
  0xFF66BB6A,
  0xFFAB47BC,
  0xFFFFCA28,
  0xFFEF5350,
];

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
    final result = await showDialog<_CategoryDraft>(
      context: context,
      builder: (_) => _CategoryDialog(category: category),
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

class _CategoryDraft {
  const _CategoryDraft(this.name, this.color, this.budgetCents);

  final String name;
  final int color;
  final int budgetCents;
}

class _CategoryDialog extends StatefulWidget {
  const _CategoryDialog({this.category});

  final ExpenseCategory? category;

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _budget = TextEditingController(
    text: (widget.category?.monthlyBudgetCents ?? 0) > 0
        ? MoneyInput.format(widget.category!.monthlyBudgetCents)
        : '',
  );
  late int _color = widget.category?.color ?? _palette.first;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.category == null ? 'Add category' : 'Edit category'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budget,
                decoration: const InputDecoration(
                  labelText: 'Monthly budget (optional)',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: MoneyInput.optionalValidator,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in _palette)
                    InkWell(
                      onTap: () => setState(() => _color = color),
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(color),
                        child: _color == color
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _CategoryDraft(
                _name.text.trim(),
                _color,
                MoneyInput.parse(_budget.text) ?? 0,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
