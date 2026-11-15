import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/currency/currency_provider.dart';
import '../../../../core/currency/money_input.dart';
import '../../domain/expense.dart';
import '../expense_providers.dart';

/// Lists recurring expense templates; pause, edit or delete them.
class RecurringExpensesDialog extends ConsumerWidget {
  const RecurringExpensesDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesProvider);
    final categories = ref.watch(expenseCategoriesProvider).value ?? const [];
    final currency = ref.watch(currencyProvider);
    final viewModel = ref.read(expensesViewModelProvider.notifier);

    String categoryName(String id) => categories
        .firstWhere(
          (c) => c.id == id,
          orElse: () => ExpenseCategory(id: id, name: 'Unknown', color: 0),
        )
        .name;

    return AlertDialog(
      title: const Text('Recurring expenses'),
      content: SizedBox(
        width: 560,
        height: 420,
        child: recurringAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(child: Text('$error')),
          data: (items) => items.isEmpty
              ? const Center(
                  child: Text(
                    'No recurring expenses yet.\nChoose "Repeat" when adding '
                    'an expense to create one.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final title = [
                      categoryName(item.categoryId),
                      if (item.vendor != null) item.vendor!,
                    ].join(' · ');
                    return ListTile(
                      leading: Switch(
                        value: item.isActive,
                        onChanged: (active) => viewModel.saveRecurring(
                          item.copyWith(isActive: active),
                        ),
                      ),
                      title: Text(title),
                      subtitle: Text(
                        '${item.frequency.label} · '
                        '${item.isActive ? 'next ${DateFormat.yMMMd().format(item.nextDueDate)}' : 'paused'}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            CurrencyFormatter.formatCents(
                              item.amountCents,
                              currency: currency,
                            ),
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          IconButton(
                            tooltip: 'Edit',
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _edit(context, viewModel, item),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete recurring expense'),
                                  content: const Text(
                                    'Future occurrences stop. Expenses already '
                                    'recorded are kept.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await viewModel.deleteRecurring(item.id);
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Future<void> _edit(
    BuildContext context,
    ExpensesViewModel viewModel,
    RecurringExpense item,
  ) async {
    final updated = await showDialog<RecurringExpense>(
      context: context,
      builder: (_) => _RecurringEditDialog(item: item),
    );
    if (updated != null) await viewModel.saveRecurring(updated);
  }
}

class _RecurringEditDialog extends StatefulWidget {
  const _RecurringEditDialog({required this.item});

  final RecurringExpense item;

  @override
  State<_RecurringEditDialog> createState() => _RecurringEditDialogState();
}

class _RecurringEditDialogState extends State<_RecurringEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount = TextEditingController(
    text: MoneyInput.format(widget.item.amountCents),
  );
  late RecurrenceFrequency _frequency = widget.item.frequency;
  late DateTime _nextDue = widget.item.nextDueDate;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit recurring expense'),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _amount,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: MoneyInput.positiveValidator,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<RecurrenceFrequency>(
                initialValue: _frequency,
                decoration: const InputDecoration(labelText: 'Repeats'),
                items: [
                  for (final f in RecurrenceFrequency.values)
                    DropdownMenuItem(value: f, child: Text(f.label)),
                ],
                onChanged: (f) => setState(() => _frequency = f ?? _frequency),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _nextDue,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _nextDue = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Next due'),
                  child: Text(DateFormat.yMMMd().format(_nextDue)),
                ),
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
              widget.item.copyWith(
                amountCents: MoneyInput.parse(_amount.text),
                frequency: _frequency,
                nextDueDate: _nextDue,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
