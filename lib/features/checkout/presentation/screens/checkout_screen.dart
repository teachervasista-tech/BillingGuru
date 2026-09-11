import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../view_models/checkout_view_model.dart';

class CheckoutScreen extends ConsumerWidget {
  const CheckoutScreen({super.key});

  String formatMoney(int cents) {
    return '€${(cents / 100).toStringAsFixed(2)}';
  }

  Future<void> _completeCashSale(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(checkoutViewModelProvider.notifier);

    await viewModel.completeCashSale(ref);

    if (!context.mounted) {
      return;
    }

    final checkoutState = ref.read(checkoutViewModelProvider);

    if (checkoutState.isCompleted) {
      ref.read(checkoutViewModelProvider.notifier).reset();
      context.go('/pos');
    }
  }

  Future<void> _completeCardSale(BuildContext context, WidgetRef ref) async {
    final viewModel = ref.read(checkoutViewModelProvider.notifier);

    await viewModel.completeCardSale(ref);

    if (!context.mounted) {
      return;
    }

    final checkoutState = ref.read(checkoutViewModelProvider);

    if (checkoutState.isCompleted) {
      ref.read(checkoutViewModelProvider.notifier).reset();
      context.go('/pos');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartViewModel = ref.read(cartProvider.notifier);
    final checkoutState = ref.watch(checkoutViewModelProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
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
                      _completeCashSale(context, ref);
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
                      _completeCardSale(context, ref);
                    },
              icon: const Icon(Icons.credit_card),
              label: const Text('Pay by card'),
            ),
            if (checkoutState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                checkoutState.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}
