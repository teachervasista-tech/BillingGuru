import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportSummary {
  const ReportSummary({
    required this.totalSalesCents,
    required this.transactionCount,
    required this.averageSaleCents,
    required this.totalQuantity,
  });

  final int totalSalesCents;
  final int transactionCount;
  final int averageSaleCents;
  final int totalQuantity;
}

class ReportsSummarySection extends ConsumerWidget {
  const ReportsSummarySection({required this.summary, super.key});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Summary',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _SummaryRow(
              label: 'Total sales',
              value: CurrencyFormatter.formatCents(
                summary.totalSalesCents,
                currency: currency,
              ),
            ),
            _SummaryRow(
              label: 'Transactions',
              value: summary.transactionCount.toString(),
            ),
            _SummaryRow(
              label: 'Average sale',
              value: CurrencyFormatter.formatCents(
                summary.averageSaleCents,
                currency: currency,
              ),
            ),
            _SummaryRow(
              label: 'Products sold',
              value: summary.totalQuantity.toString(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
