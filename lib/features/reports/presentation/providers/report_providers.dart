import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/report_models.dart';
import '../../data/services/report_local_service.dart';

final reportLocalServiceProvider = Provider<ReportLocalService>((ref) {
  return ReportLocalService();
});

final reportProvider = FutureProvider.autoDispose
    .family<ReportData, ReportPeriod>((ref, period) async {
      final service = ref.read(reportLocalServiceProvider);

      final dailySales = await service.getDailySales(
        from: period.from,
        to: period.to,
      );

      final summary = await service.getSalesSummary(
        from: period.from,
        to: period.to,
      );

      final paymentMethods = await service.getPaymentMethods(
        from: period.from,
        to: period.to,
      );

      final topProducts = await service.getTopProducts(
        from: period.from,
        to: period.to,
      );

      final lowStockProducts = await service.getLowStockProducts();

      return ReportData(
        summary: summary,
        dailySales: dailySales,
        paymentMethods: paymentMethods,
        topProducts: topProducts,
        lowStockProducts: lowStockProducts,
      );
    });

class ReportData {
  const ReportData({
    required this.summary,
    required this.dailySales,
    required this.paymentMethods,
    required this.topProducts,
    required this.lowStockProducts,
  });

  final SalesSummary summary;
  final List<DailySalesReport> dailySales;
  final List<PaymentMethodReport> paymentMethods;
  final List<TopProductReport> topProducts;
  final List<LowStockReport> lowStockProducts;
}

enum ReportPeriodType { today, lastSevenDays, thisMonth, custom }

class ReportPeriod {
  const ReportPeriod({
    required this.from,
    required this.to,
    required this.label,
  });

  final DateTime from;
  final DateTime to;
  final String label;

  factory ReportPeriod.fromType(ReportPeriodType type) {
    final now = DateTime.now();

    switch (type) {
      case ReportPeriodType.today:
        final start = DateTime(now.year, now.month, now.day);

        return ReportPeriod(
          from: start,
          to: start.add(const Duration(days: 1)),
          label: 'Today',
        );

      case ReportPeriodType.lastSevenDays:
        final end = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(const Duration(days: 1));

        return ReportPeriod(
          from: end.subtract(const Duration(days: 7)),
          to: end,
          label: 'Last 7 days',
        );

      case ReportPeriodType.thisMonth:
        final start = DateTime(now.year, now.month);

        final end = now.month == 12
            ? DateTime(now.year + 1)
            : DateTime(now.year, now.month + 1);

        return ReportPeriod(from: start, to: end, label: 'This month');

      case ReportPeriodType.custom:
        throw StateError('Custom period requires explicit dates.');
    }
  }

  factory ReportPeriod.custom({required DateTime from, required DateTime to}) {
    return ReportPeriod(
      from: from,
      to: to,
      label: '${_formatDate(from)} - ${_formatDate(to)}',
    );
  }
}

String _formatDate(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/'
      '${date.year}';
}
