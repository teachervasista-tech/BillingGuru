import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../view_models/cart_view_model.dart';

class CartSummary extends ConsumerWidget {
  const CartSummary({super.key});

  String formatMoney(WidgetRef ref, int cents) {
    final currency = ref.watch(currencyProvider);

    return CurrencyFormatter.formatCents(cents, currency: currency);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartViewModel = ref.read(cartProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.shopping_cart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cart: '
                  '${cartViewModel.itemCount} item(s)',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _SummaryRow(
              label: 'Subtotal',
              value: formatMoney(ref, cartViewModel.subtotalCents),
            ),
            _SummaryRow(
              label: 'Tax',
              value: formatMoney(ref, cartViewModel.taxCents),
            ),
            const Divider(),
            _SummaryRow(
              label: 'Total',
              value: formatMoney(ref, cartViewModel.totalCents),
              isTotal: true,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: cart.isEmpty
                  ? null
                  : () {
                      context.push('/checkout');
                    },
              icon: const Icon(Icons.payment),
              label: const Text('Checkout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.isTotal = false,
  });

  final String label;
  final String value;
  final bool isTotal;

  @override
  Widget build(BuildContext context) {
    final style = isTotal
        ? Theme.of(context).textTheme.titleLarge
              ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}
