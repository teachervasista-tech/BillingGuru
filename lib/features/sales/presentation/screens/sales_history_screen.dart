import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/printing/receipt_business_details_provider.dart';
import 'package:billing_guru/core/printing/receipt_logo.dart';
import 'package:billing_guru/core/printing/receipt_paper_size.dart';
import 'package:billing_guru/core/printing/receipt_printer_dialog.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../checkout/domain/payment.dart';
import '../../../checkout/domain/sale.dart';
import '../../data/models/sale_summary.dart';
import '../../domain/sales_period.dart';
import '../view_models/sales_view_model.dart';

class SalesHistoryScreen extends ConsumerStatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  ConsumerState<SalesHistoryScreen> createState() {
    return _SalesHistoryScreenState();
  }
}

class _SalesHistoryScreenState extends ConsumerState<SalesHistoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    Future.microtask(() {
      ref.read(salesViewModelProvider.notifier).loadSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(salesViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History'),
        actions: [
          IconButton(
            tooltip: 'Refresh sales',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(salesViewModelProvider.notifier).loadSales();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Sales history',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search sales',
                      hintText: 'Search by invoice number',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Clear search',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();

                          ref
                              .read(salesViewModelProvider.notifier)
                              .clearSearch();
                        },
                      ),
                    ),
                    onChanged: (value) {
                      ref.read(salesViewModelProvider.notifier).search(value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final selected =
                          ref.watch(salesViewModelProvider).value?.period ??
                          SalesPeriod.all;
                      final startMonth =
                          ref.watch(financialYearStartMonthProvider).value ?? 4;
                      final now = DateTime.now();

                      return Align(
                        alignment: Alignment.centerRight,
                        child: SizedBox(
                          width: 280,
                          child: DropdownButtonFormField<SalesPeriod>(
                            key: ValueKey(selected),
                            initialValue: selected,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Period',
                              prefixIcon: Icon(Icons.date_range_outlined),
                            ),
                            items: [
                              for (final period in SalesPeriod.values)
                                DropdownMenuItem(
                                  value: period,
                                  child: Text(
                                    period.label(
                                      now,
                                      financialYearStartMonth: startMonth,
                                    ),
                                  ),
                                ),
                            ],
                            onChanged: (period) {
                              if (period == null) return;
                              ref
                                  .read(salesViewModelProvider.notifier)
                                  .setPeriod(period);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: salesAsync.when(
                      loading: () {
                        return const Center(child: CircularProgressIndicator());
                      },
                      error: (error, stackTrace) {
                        return _ErrorView(
                          message: 'Unable to load sales:\n$error',
                          onRetry: () {
                            ref
                                .read(salesViewModelProvider.notifier)
                                .loadSales();
                          },
                        );
                      },
                      data: (salesState) {
                        if (salesState.sales.isEmpty) {
                          return const _EmptySalesView();
                        }

                        return RefreshIndicator(
                          onRefresh: () {
                            return ref
                                .read(salesViewModelProvider.notifier)
                                .loadSales();
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: salesState.sales.length,
                            itemBuilder: (context, index) {
                              return SaleListTile(
                                sale: salesState.sales[index],
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}

class SaleListTile extends ConsumerWidget {
  const SaleListTile({required this.sale, super.key});

  final SaleSummary sale;

  String formatDate(DateTime value) {
    final local = value.toLocal();

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${local.day}.${twoDigits(local.month)}.'
        '${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  Future<void> _reprintReceipt(BuildContext context, WidgetRef ref) async {
    final itemsAsync = ref.watch(saleItemsProvider(sale.id));

    itemsAsync.whenData((items) async {
      final saleData = Sale(
        id: sale.id,
        invoiceNumber: sale.invoiceNumber,
        items: items,
        subtotalCents: sale.subtotalCents,
        discountCents: sale.discountCents,
        taxCents: sale.taxCents,
        totalCents: sale.totalCents,
        paymentMethod: PaymentMethod.values.byName(sale.paymentMethod),
        createdAt: sale.createdAt,
        syncStatus: sale.syncStatus,
      );

      final currency = ref.read(currencyProvider);
      final template = ref.read(receiptTemplateProvider);
      final details = await ref.read(receiptBusinessDetailsProvider.future);
      final logo = await ref.read(receiptLogoProvider.future);

      if (!context.mounted) return;
      await showReceiptPrintDialog(
        context,
        paperSize: ref.read(receiptPaperSizeProvider),
        sale: saleData,
        currency: currency,
        template: template,
        businessDetails: details,
        logo: logo,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text(
          sale.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${formatDate(sale.createdAt)}\n'
          'Payment: ${sale.paymentMethod}',
        ),
        isThreeLine: true,
        trailing: SizedBox(
          width: 220,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCents(
                  sale.totalCents,
                  currency: currency,
                ),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              IconButton(
                tooltip: 'Reprint receipt',
                icon: const Icon(Icons.print_outlined),
                onPressed: () => _reprintReceipt(context, ref),
              ),
              IconButton(
                tooltip: 'View sale',
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return SaleDetailsDialog(sale: sale);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SaleDetailsDialog extends ConsumerWidget {
  const SaleDetailsDialog({required this.sale, super.key});

  final SaleSummary sale;

  Future<void> _reprintReceipt(BuildContext context, WidgetRef ref) async {
    final itemsAsync = ref.watch(saleItemsProvider(sale.id));

    itemsAsync.whenData((items) async {
      final saleData = Sale(
        id: sale.id,
        invoiceNumber: sale.invoiceNumber,
        items: items,
        subtotalCents: sale.subtotalCents,
        discountCents: sale.discountCents,
        taxCents: sale.taxCents,
        totalCents: sale.totalCents,
        paymentMethod: PaymentMethod.values.byName(sale.paymentMethod),
        createdAt: sale.createdAt,
        syncStatus: sale.syncStatus,
      );

      final currency = ref.read(currencyProvider);
      final template = ref.read(receiptTemplateProvider);
      final details = await ref.read(receiptBusinessDetailsProvider.future);
      final logo = await ref.read(receiptLogoProvider.future);

      if (!context.mounted) return;
      await showReceiptPrintDialog(
        context,
        paperSize: ref.read(receiptPaperSizeProvider),
        sale: saleData,
        currency: currency,
        template: template,
        businessDetails: details,
        logo: logo,
      );
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final itemsAsync = ref.watch(saleItemsProvider(sale.id));

    String money(int cents) =>
        CurrencyFormatter.formatCents(cents, currency: currency);

    return AlertDialog(
      title: Text(sale.invoiceNumber),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              itemsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) =>
                    Text('Unable to load items: $error'),
                data: (items) => items.isEmpty
                    ? const Text('No items in this sale')
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final item in items)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? 'Unknown product',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${item.quantity} x '
                                          '${money(item.unitPriceCents)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ),
                                      Text(money(item.totalCents)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const Divider(),
              _DetailRow(label: 'Subtotal', value: money(sale.subtotalCents)),
              _DetailRow(label: 'Discount', value: money(sale.discountCents)),
              _DetailRow(label: 'Tax', value: money(sale.taxCents)),
              const Divider(),
              _DetailRow(
                label: 'Total',
                value: money(sale.totalCents),
                isTotal: true,
              ),
              const SizedBox(height: 12),
              Text('Payment: ${sale.paymentMethod}'),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: itemsAsync.isLoading
              ? null
              : () => _reprintReceipt(context, ref),
          icon: const Icon(Icons.print_outlined),
          label: const Text('Reprint'),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _EmptySalesView extends StatelessWidget {
  const _EmptySalesView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          const Text('No sales found'),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
