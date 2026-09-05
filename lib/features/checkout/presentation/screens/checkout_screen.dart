import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../view_models/checkout_view_model.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  String formatMoney(int cents) {
    return '€${(cents / 100).toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartViewModel = ref.watch(cartProvider.notifier);
    final checkoutState = ref.watch(checkoutViewModelProvider);
    final checkoutViewModel = ref.read(checkoutViewModelProvider.notifier);

    ref.listen<CheckoutState>(checkoutViewModelProvider, (previous, next) {
      if (next.isCompleted && !next.isSaving) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sale completed successfully')),
        );
      }

      if (next.errorMessage != null &&
          next.errorMessage != previous?.errorMessage) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(next.errorMessage!)));
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.payment),
        title: const Text('Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(Icons.receipt_long, size: 64),
                    const SizedBox(height: 12),
                    const Text('Amount to pay'),
                    const SizedBox(height: 8),
                    Text(
                      formatMoney(cartViewModel.totalCents),
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: cart.isEmpty || checkoutState.isSaving
                  ? null
                  : () {
                      checkoutViewModel.completeCashSale(ref);
                    },
              icon: checkoutState.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.money),
              label: const Text('Pay with cash'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: cart.isEmpty || checkoutState.isSaving
                  ? null
                  : () {
                      checkoutViewModel.completeCardSale(ref);
                    },
              icon: const Icon(Icons.credit_card),
              label: const Text('Pay by card'),
            ),
          ],
        ),
      ),
    );
  }
}
