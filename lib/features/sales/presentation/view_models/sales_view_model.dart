import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/sale_summary.dart';
import '../../data/repositories/sales_repository.dart';
import '../../data/services/sales_local_service.dart';

final salesRepositoryProvider = Provider<SalesRepository>((ref) {
  return SalesRepository(
    localService: SalesLocalService(database: AppDatabase.instance),
  );
});

final salesViewModelProvider =
    AsyncNotifierProvider<SalesViewModel, SalesState>(SalesViewModel.new);

class SalesState {
  const SalesState({this.sales = const [], this.searchText = ''});

  final List<SaleSummary> sales;
  final String searchText;

  SalesState copyWith({List<SaleSummary>? sales, String? searchText}) {
    return SalesState(
      sales: sales ?? this.sales,
      searchText: searchText ?? this.searchText,
    );
  }
}

class SalesViewModel extends AsyncNotifier<SalesState> {
  @override
  Future<SalesState> build() async {
    final repository = ref.read(salesRepositoryProvider);
    final sales = await repository.getSales();

    return SalesState(sales: sales);
  }

  Future<void> loadSales() async {
    final repository = ref.read(salesRepositoryProvider);
    final currentSearch = state.value?.searchText ?? '';

    state = await AsyncValue.guard(() async {
      final sales = await repository.getSales(search: currentSearch);

      return SalesState(sales: sales, searchText: currentSearch);
    });
  }

  Future<void> search(String value) async {
    final repository = ref.read(salesRepositoryProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final sales = await repository.getSales(search: value);

      return SalesState(sales: sales, searchText: value);
    });
  }

  Future<void> clearSearch() {
    return search('');
  }
}
