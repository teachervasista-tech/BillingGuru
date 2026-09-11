import 'package:flutter/material.dart';

class StockAdjustmentDialog extends StatefulWidget {
  const StockAdjustmentDialog({
    super.key,
    required this.productName,
    required this.currentStock,
  });

  final String productName;
  final int currentStock;

  @override
  State<StockAdjustmentDialog> createState() {
    return _StockAdjustmentDialogState();
  }
}

class _StockAdjustmentDialogState extends State<StockAdjustmentDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();

  bool _isIncrease = true;

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.of(context).pop(
      StockAdjustmentResult(
        isIncrease: _isIncrease,
        quantity: int.parse(_quantityController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isIncrease ? 'Add stock' : 'Remove stock'),
      content: Form(
        key: _formKey,
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
          ],
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
  });

  final bool isIncrease;
  final int quantity;
}
