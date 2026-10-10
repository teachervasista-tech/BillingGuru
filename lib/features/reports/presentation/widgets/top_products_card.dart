import 'package:billing_guru/core/currency/currency.dart';
import 'package:flutter/material.dart';

import '../../data/models/report_models.dart';
import 'report_formatters.dart';

class TopProductsCard extends StatelessWidget {
  const TopProductsCard({
    required this.reports,
    required this.currency,
    this.limit = 10,
    super.key,
  });

  final List<TopProductReport> reports;
  final AppCurrency currency;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final visibleReports = reports.take(limit).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top-selling products',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (visibleReports.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(child: Text('No product sales available.')),
              )
            else
              ...visibleReports.indexed.map((entry) {
                final index = entry.$1;
                final report = entry.$2;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(report.productName),
                  subtitle: Text('${report.quantity} item(s) sold'),
                  trailing: Text(
                    formatReportCurrency(report.totalCents, currency),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
