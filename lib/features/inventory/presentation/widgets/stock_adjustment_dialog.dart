import 'package:flutter/material.dart';

import '../../../../core/currency/money_input.dart';
import '../../../checkout/domain/payment.dart';

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    required this.productName,
    required this.currentStock,
    this.currentCostCents = 0,
  });

  final String productName;
  final int currentStock;
  final int currentCostCents;

  @override
  State<StockAdjustmentDialog> createState() {
    return _StockAdjustmentDialogState();
  }
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  late final TextEditingController _costController;
  final _supplierController = TextEditingController();

  bool _isIncrease = true;
  bool _recordExpense = false;
  PaymentMethod _paymentMethod = PaymentMethod.cash;

  @override
  void initState() {
    super.initState();
    _costController = TextEditingController(
      text: widget.currentCostCents > 0
          ? MoneyInput.format(widget.currentCostCents)
          : '',
    );
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _supplierController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final unitCost = _isIncrease
        ? MoneyInput.parse(_costController.text)
        : null;

    Navigator.of(context).pop(
      StockAdjustmentResult(
        isIncrease: _isIncrease,
        quantity: int.parse(_quantityController.text.trim()),
        unitCostCents: unitCost,
        supplier: _isIncrease ? _supplierController.text.trim() : null,
        recordExpense: _isIncrease && _recordExpense && (unitCost ?? 0) > 0,
        paymentMethod: _paymentMethod,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isIncrease ? 'Add stock' : 'Remove stock'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(widget.productName),
                const SizedBox(height: 8),
                Text('Current stock: ${widget.currentStock}'),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      icon: Icon(Icons.add),
                      label: Text('Add'),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      icon: Icon(Icons.remove),
                      label: Text('Remove'),
                    ),
                  ],
                  selected: {_isIncrease},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _isIncrease = selection.first;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _quantityController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final quantity = int.tryParse(value?.trim() ?? '');

                    if (quantity == null || quantity <= 0) {
                      return 'Enter a quantity greater than zero.';
                    }

                    if (!_isIncrease && quantity > widget.currentStock) {
                      return 'Quantity cannot exceed current stock.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) {
                    _submit();
                  },
                ),
                if (_isIncrease) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('unitCostField'),
                    controller: _costController,
                    decoration: const InputDecoration(
                      labelText: 'Unit cost (optional)',
                      helperText: 'Updates the average cost price.',
                      prefixIcon: Icon(Icons.shopping_bag_outlined),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: MoneyInput.optionalValidator,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _supplierController,
                    decoration: const InputDecoration(
                      labelText: 'Supplier (optional)',
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                  ),
                  CheckboxListTile(
                    key: const Key('recordExpenseCheckbox'),
                    contentPadding: EdgeInsets.zero,
                    value: _recordExpense,
                    onChanged: (MoneyInput.parse(_costController.text) ?? 0) > 0
                        ? (value) =>
                              setState(() => _recordExpense = value ?? false)
                        : null,
                    title: const Text('Record as stock purchase expense'),
                    subtitle: const Text('Quantity × unit cost'),
                  ),
                  if (_recordExpense)
                    DropdownButtonFormField<PaymentMethod>(
                      initialValue: _paymentMethod,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Paid by'),
                      items: [
                        for (final method in PaymentMethod.values)
                          DropdownMenuItem(
                            value: method,
                            child: Text(method.label),
                          ),
                      ],
                      onChanged: (method) => setState(
                        () => _paymentMethod = method ?? PaymentMethod.cash,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}

class StockAdjustmentResult {
  const StockAdjustmentResult({
    required this.isIncrease,
    required this.quantity,
    this.unitCostCents,
    this.supplier,
    this.recordExpense = false,
    this.paymentMethod = PaymentMethod.cash,
  });

  final bool isIncrease;
  final int quantity;
  final int? unitCostCents;
  final String? supplier;
  final bool recordExpense;
  final PaymentMethod paymentMethod;
}
