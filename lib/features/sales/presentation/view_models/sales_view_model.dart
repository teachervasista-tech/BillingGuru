import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../checkout/domain/sale_item.dart';
import '../../domain/sales_period.dart';
import '../../data/models/sale_summary.dart';
import '../../data/repositories/sales_repository.dart';
import '../../data/services/sales_local_service.dart';
import '../../../customers/presentation/customer_providers.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../../inventory/presentation/view_models/inventory_view_model.dart';
import '../../../products/presentation/view_models/product_view_model.dart';
import '../../../reports/presentation/providers/report_providers.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    localService: SalesLocalService(database: ref.watch(appDatabaseProvider)),
  );
});

final saleItemsProvider = FutureProvider.family<List<SaleItem>, String>((
  ref,
  saleId,
) {
  return ref.read(salesRepositoryProvider).getSaleItems(saleId);
});

final salesViewModelProvider =
    AsyncNotifierProvider<SalesViewModel, SalesState>(SalesViewModel.new);

class SalesState {
  const SalesState({
    this.sales = const [],
    this.searchText = '',
    this.period = SalesPeriod.all,
  });

  final List<SaleSummary> sales;
  final String searchText;
  final SalesPeriod period;
}

class SalesViewModel extends AsyncNotifier<SalesState> {
  @override
  Future<SalesState> build() => _load(search: '', period: SalesPeriod.all);

  Future<SalesState> _load({
    required String search,
    required SalesPeriod period,
  }) async {
    final startMonth = await ref.read(financialYearStartMonthProvider.future);
    final range = period.rangeFor(
      DateTime.now(),
      financialYearStartMonth: startMonth,
    );
    final sales = await ref
        .read(salesRepositoryProvider)
        .getSales(search: search, range: range);

    return SalesState(sales: sales, searchText: search, period: period);
  }

  Future<void> loadSales() async {
    final search = state.value?.searchText ?? '';
    final period = state.value?.period ?? SalesPeriod.all;

    state = await AsyncValue.guard(() => _load(search: search, period: period));
  }

  Future<void> search(String value) async {
    final period = state.value?.period ?? SalesPeriod.all;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(search: value, period: period));
  }

  Future<void> setPeriod(SalesPeriod period) async {
    final search = state.value?.searchText ?? '';

    state = await AsyncValue.guard(() => _load(search: search, period: period));
  }

  Future<void> clearSearch() {
    return search('');
  }

  Future<void> voidSale(String saleId, {String? reason}) async {
    await ref.read(salesRepositoryProvider).voidSale(saleId, reason: reason);
    await _afterReturn(saleId);
  }

  Future<void> returnItems(
    String saleId,
    Map<String, int> quantities, {
    String? reason,
  }) async {
    await ref
        .read(salesRepositoryProvider)
        .returnItems(saleId, quantities, reason: reason);
    await _afterReturn(saleId);
  }

  Future<void> _afterReturn(String saleId) async {
    ref.invalidate(saleItemsProvider(saleId));
    ref.invalidate(reportProvider);
    ref.invalidate(dashboardViewModelProvider);
    ref.invalidate(inventoryViewModelProvider);
    ref.invalidate(productViewModelProvider);
    ref.invalidate(customerStatsProvider);
    ref.invalidate(customerSalesProvider);
    await loadSales();
  }
}
