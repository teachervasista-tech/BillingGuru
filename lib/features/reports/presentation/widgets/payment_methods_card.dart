import 'package:billing_guru/core/currency/currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/report_models.dart';
import 'report_formatters.dart';

class PaymentMethodsCard extends StatelessWidget {
  const PaymentMethodsCard({
    required this.reports,
    required this.currency,
    super.key,
  });

  final List<PaymentMethodReport> reports;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sales by payment method',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              const SizedBox(
                height: 180,
                child: Center(child: Text('No payment data available.')),
              )
            else
              _PaymentMethodsContent(reports: reports, currency: currency),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodsContent extends StatelessWidget {
  const _PaymentMethodsContent({required this.reports, required this.currency});

  final List<PaymentMethodReport> reports;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final totalCents = reports.fold<int>(0, (total, report) {
      return total + report.totalCents;
    });

    return SizedBox(
      height: 260,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 620;

          final chart = Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 42,
                sections: reports.indexed.map((entry) {
                  final index = entry.$1;
                  final report = entry.$2;

                  final percentage = totalCents == 0
                      ? 0.0
                      : report.totalCents / totalCents * 100;

                  return PieChartSectionData(
                    value: report.totalCents.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 76,
                    color: reportChartColor(index),
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          );

          final legend = Expanded(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: reports.length,
              separatorBuilder: (context, index) {
                return const SizedBox(height: 8);
              },
              itemBuilder: (context, index) {
                final report = reports[index];

                return Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: reportChartColor(index),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(formatPaymentMethod(report.paymentMethod)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatReportCurrency(report.totalCents, currency),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                );
              },
            ),
          );

          if (isNarrow) {
            return Column(
              children: [
                Expanded(child: chart),
                legend,
              ],
            );
          }

          return Row(children: [chart, const SizedBox(width: 24), legend]);
        },
      ),
    );
  }
}
