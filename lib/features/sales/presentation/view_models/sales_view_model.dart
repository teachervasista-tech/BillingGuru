import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../../checkout/domain/sale_item.dart';
import '../../domain/sales_period.dart';
import '../../data/models/sale_summary.dart';
import '../../data/repositories/sales_repository.dart';
import '../../data/services/sales_local_service.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    localService: SalesLocalService(database: AppDatabase.instance),
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
}
