import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;

import '../../../../core/currency/money_input.dart';
import '../../../../core/storage/app_file_storage.dart';
import '../../../../core/storage/open_file.dart';
import '../../../checkout/domain/payment.dart';
import '../../domain/expense.dart';
import '../expense_providers.dart';

/// Add or edit an expense. Returns true when saved.
Future<bool?> showExpenseFormDialog(BuildContext context, {Expense? expense}) {
  return showDialog<bool>(
    context: context,
    builder: (_) => ExpenseFormDialog(expense: expense),
  );
}

class ExpenseFormDialog extends ConsumerStatefulWidget {
  const ExpenseFormDialog({this.expense, super.key});

  final Expense? expense;

  @override
  ConsumerState<ExpenseFormDialog> createState() => _ExpenseFormDialogState();
}

class _ExpenseFormDialogState extends ConsumerState<ExpenseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _tax;
  late final TextEditingController _vendor;
  late final TextEditingController _reference;
  late final TextEditingController _note;
  late DateTime _date;
  String? _categoryId;
  late PaymentMethod _method;
  String? _attachmentPath;
  RecurrenceFrequency? _repeat;
  bool _saving = false;

  bool get _isEditing => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(
      text: e == null ? '' : MoneyInput.format(e.amountCents),
    );
    _tax = TextEditingController(
      text: e == null || e.taxCents == 0 ? '' : MoneyInput.format(e.taxCents),
    );
    _vendor = TextEditingController(text: e?.vendor ?? '');
    _reference = TextEditingController(text: e?.referenceNo ?? '');
    _note = TextEditingController(text: e?.note ?? '');
    _date = e?.expenseDate ?? DateTime.now();
    _categoryId = e?.categoryId;
    _method = e?.paymentMethod ?? PaymentMethod.cash;
    _attachmentPath = e?.attachmentPath;
  }

  @override
  void dispose() {
    for (final c in [_amount, _tax, _vendor, _reference, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickAttachment() async {
    final path = await AppFileStorage.pickAndStore(
      folderName: AppFileStorage.expenseAttachmentsFolder,
      label: 'Receipts',
      extensions: AppFileStorage.attachmentExtensions,
    );
    if (path != null) setState(() => _attachmentPath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final viewModel = ref.read(expensesViewModelProvider.notifier);
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final amount = MoneyInput.parse(_amount.text)!;
      String? recurringId = widget.expense?.recurringId;

      if (!_isEditing && _repeat != null) {
        final recurring = RecurringExpense(
          id: viewModel.newId(),
          categoryId: _categoryId!,
          amountCents: amount,
          paymentMethod: _method,
          frequency: _repeat!,
          nextDueDate: _repeat!.next(_date),
          createdAt: DateTime.now(),
          vendor: _vendor.text,
          note: _note.text,
        );
        await viewModel.saveRecurring(recurring);
        recurringId = recurring.id;
      }

      final previousAttachment = widget.expense?.attachmentPath;
      await viewModel.saveExpense(
        Expense(
          id: widget.expense?.id ?? viewModel.newId(),
          categoryId: _categoryId!,
          amountCents: amount,
          taxCents: MoneyInput.parse(_tax.text) ?? 0,
          paymentMethod: _method,
          vendor: _vendor.text,
          referenceNo: _reference.text,
          note: _note.text,
          attachmentPath: _attachmentPath,
          expenseDate: _date,
          createdAt: widget.expense?.createdAt ?? DateTime.now(),
          recurringId: recurringId,
        ),
      );
      if (previousAttachment != null && previousAttachment != _attachmentPath) {
        await AppFileStorage.delete(previousAttachment);
      }
      navigator.pop(true);
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to save the expense: $error')),
      );
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(expenseCategoriesProvider).value ?? const [];
    final choices = categories
        .where((c) => c.isActive || c.id == _categoryId)
        .toList();

    return AlertDialog(
      title: Text(_isEditing ? 'Edit expense' : 'Add expense'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            prefixIcon: Icon(Icons.event_outlined),
                          ),
                          child: Text(DateFormat.yMMMd().format(_date)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        key: const Key('expenseCategoryField'),
                        initialValue: _categoryId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(Icons.category_outlined),
                        ),
                        items: [
                          for (final c in choices)
                            DropdownMenuItem(
                              value: c.id,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 6,
                                    backgroundColor: Color(c.color),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      c.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                        validator: (v) =>
                            v == null ? 'Choose a category.' : null,
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        key: const Key('expenseAmountField'),
                        controller: _amount,
                        autofocus: !_isEditing,
                        decoration: const InputDecoration(
                          labelText: 'Amount (incl. tax)',
                          prefixIcon: Icon(Icons.payments_outlined),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: MoneyInput.positiveValidator,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _tax,
                        decoration: const InputDecoration(
                          labelText: 'Tax included (optional)',
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (value) {
                          final error = MoneyInput.optionalValidator(value);
                          if (error != null) return error;
                          final tax = MoneyInput.parse(value) ?? 0;
                          final amount = MoneyInput.parse(_amount.text) ?? 0;
                          return tax > amount
                              ? 'Tax cannot exceed the amount.'
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<PaymentMethod>(
                        initialValue: _method,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Paid by',
                          prefixIcon: Icon(Icons.account_balance_wallet),
                        ),
                        items: [
                          for (final m in PaymentMethod.values)
                            DropdownMenuItem(value: m, child: Text(m.label)),
                        ],
                        onChanged: (m) =>
                            setState(() => _method = m ?? _method),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: const Key('expenseVendorField'),
                        controller: _vendor,
                        decoration: const InputDecoration(
                          labelText: 'Paid to / vendor',
                          prefixIcon: Icon(Icons.store_outlined),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _reference,
                  decoration: const InputDecoration(
                    labelText: 'Bill / reference number',
                    prefixIcon: Icon(Icons.tag),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _note,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    prefixIcon: Icon(Icons.notes),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.attach_file),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _attachmentPath == null
                          ? const Text('No receipt attached')
                          : InkWell(
                              onTap: () => openWithSystem(_attachmentPath!),
                              child: Text(
                                p.basename(_attachmentPath!),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                    ),
                    if (_attachmentPath != null)
                      IconButton(
                        tooltip: 'Remove receipt',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() => _attachmentPath = null),
                      ),
                    TextButton.icon(
                      onPressed: _pickAttachment,
                      icon: const Icon(Icons.upload_file),
                      label: Text(
                        _attachmentPath == null ? 'Attach receipt' : 'Replace',
                      ),
                    ),
                  ],
                ),
                if (!_isEditing) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<RecurrenceFrequency?>(
                    key: const Key('expenseRepeatField'),
                    initialValue: _repeat,
                    decoration: const InputDecoration(
                      labelText: 'Repeat',
                      prefixIcon: Icon(Icons.repeat),
                      helperText:
                          'Recurring expenses are added automatically on '
                          'each due date.',
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Does not repeat'),
                      ),
                      for (final f in RecurrenceFrequency.values)
                        DropdownMenuItem(value: f, child: Text(f.label)),
                    ],
                    onChanged: (f) => setState(() => _repeat = f),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving
              ? null
              : () {
                  // Drop a receipt picked in this dialog but never saved.
                  if (_attachmentPath != widget.expense?.attachmentPath) {
                    AppFileStorage.delete(_attachmentPath);
                  }
                  Navigator.of(context).pop(false);
                },
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Save'),
        ),
      ],
    );
  }
}
