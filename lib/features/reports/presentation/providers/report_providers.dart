import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/period/date_range.dart';
import '../../../../core/settings/app_settings_provider.dart';
import '../../../expenses/data/expense_local_service.dart';
import '../../../expenses/domain/expense.dart';
import '../../data/models/report_models.dart';
import '../../data/services/report_local_service.dart';

enum ReportPeriodType {
  today(PeriodPreset.today, 'Today', 'today'),
  last7Days(PeriodPreset.last7Days, 'Last 7 days', 'in the last 7 days'),
  thisMonth(PeriodPreset.month, 'This month', 'this month'),
  lastMonth(PeriodPreset.lastMonth, 'Last month', 'last month'),
  financialYear(
    PeriodPreset.financialYear,
    'Financial year',
    'this financial year',
  );

  const ReportPeriodType(this.preset, this.label, this.phrase);

  final PeriodPreset preset;
  final String label;

  /// Used in sentences, e.g. "Sold 3 units in the last 7 days".
  final String phrase;
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
    this.profitLoss = const ProfitLoss.empty(),
    this.expenseSpend = const [],
  });

  final SalesSummary summary;
  final List<DailySalesReport> dailySales;
  final List<PaymentMethodReport> paymentMethods;
  final List<TopProductReport> topProducts;
  final List<LowStockReport> lowStockProducts;
  final ProfitLoss profitLoss;
  final List<CategorySpend> expenseSpend;
}

final reportLocalServiceProvider = Provider<ReportLocalService>((ref) {
  return ReportLocalService(database: ref.watch(appDatabaseProvider));
});

final reportProvider = FutureProvider.autoDispose
    .family<ReportData, ReportFilter>((ref, filter) async {
      final service = ref.read(reportLocalServiceProvider);
      final expenses = ExpenseLocalService(
        database: ref.read(appDatabaseProvider),
      );
      final fyStart = ref.read(appSettingsProvider).financialYearStartMonth;
      final range = filter.type.preset.rangeFor(
        DateTime.now(),
        financialYearStartMonth: fyStart,
      )!;
      final from = range.from;
      final to = range.to;

      return ReportData(
        summary: await service.getSalesSummary(from: from, to: to),
        dailySales: await service.getDailySales(from: from, to: to),
        paymentMethods: await service.getPaymentMethods(from: from, to: to),
        topProducts: await service.getTopProducts(from: from, to: to),
        lowStockProducts: await service.getLowSellingProducts(
          from: from,
          to: to,
        ),
        profitLoss: await service.getProfitLoss(from: from, to: to),
        expenseSpend: await expenses.spendByCategory(range),
      );
    });
