import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_item.dart';
import '../view_models/cart_view_model.dart';

class CartItemTile extends ConsumerWidget {
  const CartItemTile({super.key, required this.item});

  final CartItem item;

  String formatMoney(WidgetRef ref, int cents) {
    final currency = ref.watch(currencyProvider);

    return CurrencyFormatter.formatCents(cents, currency: currency);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartViewModel = ref.read(cartProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const Icon(Icons.shopping_bag_outlined),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('${formatMoney(ref, item.product.priceCents)} each'),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Decrease quantity',
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                cartViewModel.decreaseQuantity(item.product.id);
              },
            ),
            Text(
              '${item.quantity}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              tooltip: 'Increase quantity',
              icon: const Icon(Icons.add_circle_outline),
              onPressed: item.quantity >= item.product.stockQuantity
                  ? null
                  : () {
                      cartViewModel.increaseQuantity(item.product.id);
                    },
            ),
            const SizedBox(width: 8),
            Text(
              formatMoney(ref, item.totalCents),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            IconButton(
              tooltip: 'Remove item',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                cartViewModel.removeProduct(item.product.id);
              },
            ),
          ],
        ),
      ),
    );
  }
}
