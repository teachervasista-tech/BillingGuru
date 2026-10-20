import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/printing/receipt_business_details_provider.dart';
import 'package:billing_guru/core/printing/receipt_logo.dart';
import 'package:billing_guru/core/printing/receipt_paper_size.dart';
import 'package:billing_guru/core/printing/receipt_printer_dialog.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/checkout/domain/sale.dart';
import 'package:billing_guru/core/config/app_features.dart';
import 'package:billing_guru/features/checkout/presentation/view_models/checkout_view_model.dart';
import 'package:billing_guru/core/tax/tax_rate_provider.dart';
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

  Future<void> _printReceipt(BuildContext context, WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    final Sale sale;
    try {
      sale = await ref
          .read(checkoutViewModelProvider.notifier)
          .recordSale(cart, PaymentMethod.cash);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to save the sale: $error')),
      );
      return;
    }
    final currency = ref.read(currencyProvider);
    final template = ref.read(receiptTemplateProvider);
    final details = await ref.read(receiptBusinessDetailsProvider.future);
    final logo = await ref.read(receiptLogoProvider.future);

    if (!context.mounted) return;
    final printed = await showReceiptPrintDialog(
      context,
      paperSize: ref.read(receiptPaperSizeProvider),
      sale: sale,
      currency: currency,
      template: template,
      businessDetails: details,
      logo: logo,
    );
    if (printed) ref.read(cartProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    ref.watch(defaultTaxRateProvider);
    final cartViewModel = ref.read(cartProvider.notifier);
    final checkoutEnabled = AppFeatures.instance.checkoutEnabled;

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
                  style: Theme.of(context).textTheme.titleMedium,
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
            if (checkoutEnabled)
              FilledButton.icon(
                onPressed: cart.isEmpty
                    ? null
                    : () {
                        context.push('/checkout');
                      },
                icon: const Icon(Icons.payment),
                label: const Text('Checkout'),
              )
            else
              FilledButton.icon(
                onPressed: cart.isEmpty
                    ? null
                    : () => _printReceipt(context, ref),
                icon: const Icon(Icons.print),
                label: const Text('Print'),
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
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;

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
