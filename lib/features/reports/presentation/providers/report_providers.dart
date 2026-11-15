import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/period/date_range.dart';
import '../../data/models/report_models.dart';
import '../../data/services/report_local_service.dart';

enum ReportPeriodType {
  today(PeriodPreset.today),
  last7Days(PeriodPreset.last7Days),
  thisMonth(PeriodPreset.month);

  const ReportPeriodType(this.preset);

  final PeriodPreset preset;
}

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
  return ReportLocalService(database: ref.watch(appDatabaseProvider));
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

      final lowStockProducts = await service.getLowSellingProducts(
        from: period.from,
        to: period.to,
      );

      return ReportData(
        summary: summary,
        dailySales: dailySales,
        paymentMethods: paymentMethods,
        topProducts: topProducts,
        lowStockProducts: lowStockProducts,
      );
    });

ReportPeriod _periodFromFilter(ReportFilter filter) {
  final range = filter.type.preset.rangeFor(DateTime.now())!;
  return ReportPeriod(from: range.from, to: range.to);
}
