import 'package:flutter/material.dart';

import '../../../checkout/domain/sale_item.dart';

/// Confirmation with an optional free-text reason. Pops the reason
/// (possibly empty) on confirm, null on cancel.
class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    super.key,
  });

  final String title;
  final String message;
  final String confirmLabel;

  @override
  State<ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends State<ReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(widget.message),
            const SizedBox(height: 12),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'Reason (optional)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _reason.text),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}

class ReturnItemsResult {
  const ReturnItemsResult(this.quantities, this.reason);

  /// Sale item id -> units to return.
  final Map<String, int> quantities;
  final String reason;
}

/// Pick how many units of each item the customer brings back.
class ReturnItemsDialog extends StatefulWidget {
  const ReturnItemsDialog({required this.items, super.key});

  final List<SaleItem> items;

  @override
  State<ReturnItemsDialog> createState() => _ReturnItemsDialogState();
}

class _ReturnItemsDialogState extends State<ReturnItemsDialog> {
  final _reason = TextEditingController();
  late final Map<String, int> _quantities = {
    for (final item in widget.items) item.id: 0,
  };

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  int get _selected => _quantities.values.fold(0, (a, b) => a + b);

  @override
  Widget build(BuildContext context) {
    final returnable = widget.items.where((i) => i.returnableQuantity > 0);

    return AlertDialog(
      title: const Text('Return items'),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final item in returnable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.productName ?? item.productId),
                  subtitle: Text(
                    '${item.returnableQuantity} of ${item.quantity} returnable',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: _quantities[item.id]! > 0
                            ? () => setState(
                                () => _quantities[item.id] =
                                    _quantities[item.id]! - 1,
                              )
                            : null,
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${_quantities[item.id]}',
                          key: Key('returnQty-${item.id}'),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      IconButton(
                        key: Key('returnInc-${item.id}'),
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed:
                            _quantities[item.id]! < item.returnableQuantity
                            ? () => setState(
                                () => _quantities[item.id] =
                                    _quantities[item.id]! + 1,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _reason,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
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
          onPressed: _selected == 0
              ? null
              : () => Navigator.pop(
                  context,
                  ReturnItemsResult(
                    Map.of(_quantities)..removeWhere((_, q) => q == 0),
                    _reason.text,
                  ),
                ),
          child: Text('Return $_selected item${_selected == 1 ? '' : 's'}'),
        ),
      ],
    );
  }
}
