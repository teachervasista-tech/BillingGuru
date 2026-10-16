import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/inventory_item.dart';
import '../view_models/inventory_view_model.dart';
import 'stock_adjustment_dialog.dart';

class InventoryListItem extends ConsumerWidget {
  const InventoryListItem({super.key, required this.item});

  final InventoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLowStock = item.isLowStock();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isLowStock
              ? Colors.red.withValues(alpha: 0.15)
              : Colors.green.withValues(alpha: 0.15),
          foregroundColor: isLowStock ? Colors.red : Colors.green,
          child: Icon(isLowStock ? Icons.warning_amber : Icons.inventory_2),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Barcode: ${item.barcode}\n'
          'Price: ${formatMoney(ref, item.priceCents)}',
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 190,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${item.stockQuantity}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? Colors.red : Colors.green,
                    ),
                  ),
                  Text(
                    isLowStock ? 'Low stock' : 'In stock',
                    style: TextStyle(
                      color: isLowStock ? Colors.red : Colors.green,
                    ),
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Adjust stock',
                icon: const Icon(Icons.tune),
                onPressed: () {
                  _adjustStock(context, ref);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String formatMoney(WidgetRef ref, int cents) {
    final currency = ref.watch(currencyProvider);

    return CurrencyFormatter.formatCents(cents, currency: currency);
  }

  Future<void> _adjustStock(BuildContext context, WidgetRef ref) async {
    final result = await showDialog<StockAdjustmentResult>(
      context: context,
      builder: (context) {
        return StockAdjustmentDialog(
          productName: item.name,
          currentStock: item.stockQuantity,
        );
      },
    );

    if (result == null || !context.mounted) {
      return;
    }

    final viewModel = ref.read(inventoryViewModelProvider.notifier);

    if (result.isIncrease) {
      await viewModel.increaseStock(
        productId: item.productId,
        quantity: result.quantity,
      );
    } else {
      await viewModel.decreaseStock(
        productId: item.productId,
        quantity: result.quantity,
      );
    }
  }
}
