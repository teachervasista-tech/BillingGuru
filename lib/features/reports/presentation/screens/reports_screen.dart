import 'package:billing_guru/features/reports/data/models/report_models.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/report_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() {
    return _ReportsPageState();
  }
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  ReportPeriodType _periodType = ReportPeriodType.lastSevenDays;
  DateTimeRange? _customDateRange;

  @override
  Widget build(BuildContext context) {
    final period = _currentReportPeriod();

    final reportAsync = ref.watch(reportProvider(period));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DropdownButton<ReportPeriodType>(
              value: _periodType,
              underline: const SizedBox.shrink(),
              items: const [
                DropdownMenuItem(
                  value: ReportPeriodType.today,
                  child: Text('Today'),
                ),
                DropdownMenuItem(
                  value: ReportPeriodType.lastSevenDays,
                  child: Text('Last 7 days'),
                ),
                DropdownMenuItem(
                  value: ReportPeriodType.thisMonth,
                  child: Text('This month'),
                ),
                DropdownMenuItem(
                  value: ReportPeriodType.custom,
                  child: Text('Custom range'),
                ),
              ],
              onChanged: (periodType) async {
                if (periodType == null) {
                  return;
                }

                if (periodType == ReportPeriodType.custom) {
                  await _selectCustomDateRange();
                  return;
                }

                setState(() {
                  _periodType = periodType;
                  _customDateRange = null;
                });
              },
            ),
          ),
          if (_periodType == ReportPeriodType.custom)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: OutlinedButton.icon(
                onPressed: _selectCustomDateRange,
                icon: const Icon(Icons.date_range),
                label: Text(period.label),
              ),
            ),
        ],
      ),
      body: reportAsync.when(
        loading: () {
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stackTrace) {
          return Center(
            child: Text(
              'Unable to load reports.\n$error',
              textAlign: TextAlign.center,
            ),
          );
        },
        data: (report) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(reportProvider(period));
            },
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _SummarySection(summary: report.summary),
                const SizedBox(height: 24),
                _DailySalesCard(reports: report.dailySales),
                const SizedBox(height: 24),
                _PaymentMethodsCard(reports: report.paymentMethods),
                const SizedBox(height: 24),
                _TopProductsCard(reports: report.topProducts),
                const SizedBox(height: 24),
                _LowStockCard(products: report.lowStockProducts),
              ],
            ),
          );
        },
      ),
    );
  }

  ReportPeriod _currentReportPeriod() {
    if (_periodType == ReportPeriodType.custom) {
      final customRange = _customDateRange;

      if (customRange == null) {
        return ReportPeriod.fromType(ReportPeriodType.lastSevenDays);
      }

      return ReportPeriod.custom(
        from: _startOfDay(customRange.start),
        to: _endOfDay(customRange.end),
      );
    }

    return ReportPeriod.fromType(_periodType);
  }

  DateTime _startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(const Duration(days: 1));
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();

    final initialRange =
        _customDateRange ??
        DateTimeRange(start: now.subtract(const Duration(days: 6)), end: now);

    final selectedRange = await showDateRangePicker(
      context: context,
      initialDateRange: initialRange,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Select sales report period',
      cancelText: 'Cancel',
      confirmText: 'Apply',
    );

    if (!mounted || selectedRange == null) {
      return;
    }

    setState(() {
      _customDateRange = selectedRange;
      _periodType = ReportPeriodType.custom;
    });
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary});

  final SalesSummary summary;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _SummaryCard(
          title: 'Total sales',
          value: _formatCurrency(summary.totalSalesCents),
          icon: Icons.payments_outlined,
        ),
        _SummaryCard(
          title: 'Transactions',
          value: '${summary.totalTransactions}',
          icon: Icons.receipt_long_outlined,
        ),
        _SummaryCard(
          title: 'Items sold',
          value: '${summary.totalItems}',
          icon: Icons.shopping_basket_outlined,
        ),
        _SummaryCard(
          title: 'Average sale',
          value: _formatCurrency(summary.averageTransactionCents),
          icon: Icons.trending_up,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(
                icon,
                size: 30,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(value, style: Theme.of(context).textTheme.titleLarge),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySalesCard extends StatelessWidget {
  const _DailySalesCard({required this.reports});

  final List<DailySalesReport> reports;

  @override
  Widget build(BuildContext context) {
    final maxValue = reports.isEmpty
        ? 100.0
        : reports
                  .map((report) => report.totalCents)
                  .reduce((a, b) => a > b ? a : b)
                  .toDouble() *
              1.2;

    return _ReportCard(
      title: 'Sales trend',
      child: SizedBox(
        height: 280,
        child: reports.isEmpty
            ? const _EmptyReport(message: 'No sales for this period.')
            : BarChart(
                BarChartData(
                  maxY: maxValue == 0 ? 100 : maxValue,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
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
                              style: const TextStyle(fontSize: 11),
                            ),
                          );
                        },
                      ),
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
                          borderRadius: BorderRadius.circular(4),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}

class _PaymentMethodsCard extends StatelessWidget {
  const _PaymentMethodsCard({required this.reports});

  final List<PaymentMethodReport> reports;

  @override
  Widget build(BuildContext context) {
    final total = reports.fold<int>(
      0,
      (sum, report) => sum + report.totalCents,
    );

    return _ReportCard(
      title: 'Sales by payment method',
      child: reports.isEmpty
          ? const _EmptyReport(message: 'No payment data available.')
          : SizedBox(
              height: 260,
              child: Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 42,
                        sections: reports.indexed.map((entry) {
                          final index = entry.$1;
                          final report = entry.$2;
                          final percentage = total == 0
                              ? 0
                              : report.totalCents / total * 100;

                          return PieChartSectionData(
                            value: report.totalCents.toDouble(),
                            title: '${percentage.toStringAsFixed(0)}%',
                            radius: 75,
                            color: _chartColor(index),
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: reports.indexed.map((entry) {
                        final index = entry.$1;
                        final report = entry.$2;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _chartColor(index),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${report.paymentMethod}: '
                                  '${_formatCurrency(report.totalCents)}',
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TopProductsCard extends StatelessWidget {
  const _TopProductsCard({required this.reports});

  final List<TopProductReport> reports;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: 'Top-selling products',
      child: reports.isEmpty
          ? const _EmptyReport(message: 'No product sales available.')
          : Column(
              children: reports.indexed.map((entry) {
                final index = entry.$1;
                final report = entry.$2;

                return ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(report.productName),
                  subtitle: Text('${report.quantity} items sold'),
                  trailing: Text(_formatCurrency(report.totalCents)),
                );
              }).toList(),
            ),
    );
  }
}

class _LowStockCard extends StatelessWidget {
  const _LowStockCard({required this.products});

  final List<LowStockReport> products;

  @override
  Widget build(BuildContext context) {
    return _ReportCard(
      title: 'Low-stock products',
      child: products.isEmpty
          ? const _EmptyReport(
              message: 'No products are below the stock threshold.',
            )
          : Column(
              children: products.map((product) {
                return ListTile(
                  leading: const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(product.productName),
                  subtitle: Text('Code: ${product.shortCode}'),
                  trailing: Text('${product.stockQuantity} left'),
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
            Text(title, style: Theme.of(context).textTheme.titleMedium),
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
    return SizedBox(height: 120, child: Center(child: Text(message)));
  }
}

Color _chartColor(int index) {
  const colors = [
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.red,
    Colors.teal,
  ];

  return colors[index % colors.length];
}

String _formatCurrency(int cents) {
  return '€${(cents / 100).toStringAsFixed(2)}';
}
