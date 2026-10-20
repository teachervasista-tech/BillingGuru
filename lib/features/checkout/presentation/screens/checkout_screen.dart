import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/tax/tax_rate_provider.dart';
import 'package:billing_guru/core/printing/receipt_business_details_provider.dart';
import 'package:billing_guru/core/printing/receipt_logo.dart';
import 'package:billing_guru/core/printing/receipt_paper_size.dart';
import 'package:billing_guru/core/printing/receipt_printer_dialog.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../../domain/payment.dart';
import '../../domain/payment_option.dart';
import '../providers/payment_options_provider.dart';
import '../view_models/checkout_view_model.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  String? _selectedOptionId;

  String formatMoney(WidgetRef ref, int cents) {
    final currency = ref.watch(currencyProvider);

    return CurrencyFormatter.formatCents(cents, currency: currency);
  }

  PaymentOption? _selectedOption(List<PaymentOption> options) {
    for (final option in options) {
      if (option.id == _selectedOptionId) return option;
    }
    return options.firstOrNull;
  }

  Future<void> _pay(PaymentOption option) async {
    await ref
        .read(checkoutViewModelProvider.notifier)
        .completeSale(ref, option.method);

    if (!mounted) {
      return;
    }

    final checkoutState = ref.read(checkoutViewModelProvider);

    if (checkoutState.isCompleted) {
      ref.read(checkoutViewModelProvider.notifier).reset();
      context.go('/pos');
    }
  }

  Future<void> _printReceipt(PaymentOption? option) async {
    final cart = ref.read(cartProvider);
    final sale = await ref
        .read(checkoutViewModelProvider.notifier)
        .buildSale(cart, option?.method ?? PaymentMethod.cash);
    final currency = ref.read(currencyProvider);
    final template = ref.read(receiptTemplateProvider);
    final details = await ref.read(receiptBusinessDetailsProvider.future);
    final logo = await ref.read(receiptLogoProvider.future);

    if (!mounted) return;
    await showReceiptPrintDialog(
      context,
      paperSize: ref.read(receiptPaperSizeProvider),
      sale: sale,
      currency: currency,
      template: template,
      businessDetails: details,
      logo: logo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    ref.watch(defaultTaxRateProvider);
    final cartViewModel = ref.read(cartProvider.notifier);
    final checkoutState = ref.watch(checkoutViewModelProvider);
    final paymentOptions = ref.watch(paymentOptionsProvider);
    final selectedOption = _selectedOption(paymentOptions);
    final checkoutDateTime = DateFormat('dd MMM yyyy, HH:mm')
        .format(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Order summary',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text('Date and time: $checkoutDateTime'),
                          const Divider(height: 24),
                          if (cart.isEmpty)
                            const Text('No items in cart')
                          else
                            ...cart.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.quantity} x ${formatMoney(ref, item.product.priceCents)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                        Text(formatMoney(ref, item.totalCents)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const Divider(height: 16),
                          _CheckoutAmountRow(
                            label: 'Subtotal',
                            amount: formatMoney(
                              ref,
                              cartViewModel.subtotalCents,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _CheckoutAmountRow(
                            label: 'Tax',
                            amount: formatMoney(ref, cartViewModel.taxCents),
                          ),
                          const Divider(height: 24),
                          _CheckoutAmountRow(
                            label: 'Total',
                            amount: formatMoney(ref, cartViewModel.totalCents),
                            emphasized: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment option',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (paymentOptions.isEmpty)
                    const Text(
                      'No payment options configured. Add one in Settings.',
                    ),
                  for (final option in paymentOptions)
                    Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        selected: option.id == selectedOption?.id,
                        leading: Icon(
                          option.id == selectedOption?.id
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        title: Text(option.name),
                        onTap: () =>
                            setState(() => _selectedOptionId = option.id),
                      ),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        cart.isEmpty ||
                            checkoutState.isSaving ||
                            selectedOption == null
                        ? null
                        : () => _pay(selectedOption),
                    icon: checkoutState.isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.payments_outlined),
                    label: const Text('Pay'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: cart.isEmpty
                        ? null
                        : () => _printReceipt(selectedOption),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print receipt'),
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
          ),
        ),
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}

class _CheckoutAmountRow extends StatelessWidget {
  const _CheckoutAmountRow({
    required this.label,
    required this.amount,
    this.emphasized = false,
  });

  final String label;
  final String amount;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final style = emphasized
        ? Theme.of(context).textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyMedium;

    return Row(
      children: [
        Expanded(child: Text(label, style: style)),
        Text(amount, style: style),
      ],
    );
  }
}
