import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/report_models.dart';
import '../../data/services/report_local_service.dart';

enum ReportPeriodType { today, last7Days, thisMonth }

class ReportFilter {
  const ReportFilter({required this.type});

  final ReportPeriodType type;

  @override
  bool operator ==(Object other) {
    return other is ReportFilter && other.type == type;
  }

  @override
  int get hashCode => type.hashCode;
}

class ReportPeriod {
  const ReportPeriod({required this.from, required this.to});

  final DateTime from;
  final DateTime to;
}

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

final reportLocalServiceProvider = Provider<ReportLocalService>((ref) {
  return ReportLocalService();
});

final reportProvider = FutureProvider.autoDispose
    .family<ReportData, ReportFilter>((ref, filter) async {
      final service = ref.read(reportLocalServiceProvider);

      final period = _periodFromFilter(filter);

      final summary = await service.getSalesSummary(
        from: period.from,
        to: period.to,
      );

      final dailySales = await service.getDailySales(
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

ReportPeriod _periodFromFilter(ReportFilter filter) {
  final now = DateTime.now();

  switch (filter.type) {
    case ReportPeriodType.today:
      final start = DateTime(now.year, now.month, now.day);

      return ReportPeriod(from: start, to: start.add(const Duration(days: 1)));

    case ReportPeriodType.last7Days:
      final end = DateTime(
        now.year,
        now.month,
        now.day,
      ).add(const Duration(days: 1));

      return ReportPeriod(from: end.subtract(const Duration(days: 7)), to: end);

    case ReportPeriodType.thisMonth:
      final start = DateTime(now.year, now.month);

      final end = now.month == 12
          ? DateTime(now.year + 1)
          : DateTime(now.year, now.month + 1);

      return ReportPeriod(from: start, to: end);
  }
}
