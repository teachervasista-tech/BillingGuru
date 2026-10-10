import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../data/models/sale_summary.dart';
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
          width: 150,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                CurrencyFormatter.formatCents(
                  sale.totalCents,
                  currency: currency,
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    return AlertDialog(
      title: Text(sale.invoiceNumber),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DetailRow(
              label: 'Subtotal',
              value: CurrencyFormatter.formatCents(
                sale.subtotalCents,
                currency: currency,
              ),
            ),
            _DetailRow(
              label: 'Discount',
              value: CurrencyFormatter.formatCents(
                sale.discountCents,
                currency: currency,
              ),
            ),
            _DetailRow(
              label: 'Tax',
              value: CurrencyFormatter.formatCents(
                sale.taxCents,
                currency: currency,
              ),
            ),
            const Divider(),
            _DetailRow(
              label: 'Total',
              value: CurrencyFormatter.formatCents(
                sale.totalCents,
                currency: currency,
              ),
              isTotal: true,
            ),
            const SizedBox(height: 12),
            Text('Payment: ${sale.paymentMethod}'),
            Text('Status: ${sale.syncStatus}'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
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
              ?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;

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
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey),
          SizedBox(height: 12),
          Text('No sales found'),
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
