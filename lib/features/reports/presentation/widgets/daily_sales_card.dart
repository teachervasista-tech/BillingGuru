import 'package:billing_guru/core/currency/currency.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/report_models.dart';
import 'report_formatters.dart';

class DailySalesCard extends StatelessWidget {
  const DailySalesCard({
    required this.reports,
    required this.currency,
    super.key,
  });

  final List<DailySalesReport> reports;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: 'Sales trend',
      child: SizedBox(
        height: 300,
        child: reports.isEmpty
            ? const _EmptyReport(message: 'No sales for this period.')
            : _DailySalesChart(reports: reports, currency: currency),
      ),
    );
  }
}

class _DailySalesChart extends StatelessWidget {
  const _DailySalesChart({required this.reports, required this.currency});

  final List<DailySalesReport> reports;
  final AppCurrency currency;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final highestCents = reports.map((report) => report.totalCents).reduce((
      first,
      second,
    ) {
      return first > second ? first : second;
    });

    final maxY = highestCents <= 0 ? 100.0 : highestCents.toDouble() * 1.2;

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY / 4,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: colorScheme.outlineVariant, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 56,
              interval: maxY / 4,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    formatCompactReportCurrency(value.toInt(), currency),
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();

                if (index < 0 || index >= reports.length) {
                  return const SizedBox.shrink();
                }

                final date = reports[index].date;

                return SideTitleWidget(
                  meta: meta,
                  child: Text(
                    '${date.day}/${date.month}',
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final report = reports[group.x.toInt()];

              return BarTooltipItem(
                '${formatFullReportDate(report.date)}\n'
                '${formatReportCurrency(report.totalCents, currency)}\n'
                '${report.transactionCount} transaction(s)',
                TextStyle(
                  color: colorScheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        barGroups: reports.indexed.map((entry) {
          final index = entry.$1;
          final report = entry.$2;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: report.totalCents.toDouble(),
                width: 22,
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _EmptyReport extends StatelessWidget {
  const _EmptyReport({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(child: Text(message, textAlign: TextAlign.center)),
    );
  }
}
