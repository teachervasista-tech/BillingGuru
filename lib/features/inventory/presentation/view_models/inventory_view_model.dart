import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/inventory_item.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/services/inventory_local_service.dart';

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  return InventoryRepository(
    localService: InventoryLocalService(database: AppDatabase.instance),
  );
});

final inventoryViewModelProvider =
    AsyncNotifierProvider<InventoryViewModel, InventoryState>(
      InventoryViewModel.new,
    );

class InventoryState {
  const InventoryState({
    this.items = const [],
    this.searchText = '',
    this.lowStockOnly = false,
  });

  final List<InventoryItem> items;
  final String searchText;
  final bool lowStockOnly;

  InventoryState copyWith({
    List<InventoryItem>? items,
    String? searchText,
    bool? lowStockOnly,
  }) {
    return InventoryState(
      items: items ?? this.items,
      searchText: searchText ?? this.searchText,
      lowStockOnly: lowStockOnly ?? this.lowStockOnly,
    );
  }
}

class InventoryViewModel extends AsyncNotifier<InventoryState> {
  static const int lowStockThreshold = 10;

  @override
  Future<InventoryState> build() async {
    return _loadState();
  }

  Future<InventoryState> _loadState({
    String? searchText,
    bool? lowStockOnly,
  }) async {
    final repository = ref.read(inventoryRepositoryProvider);

    final currentSearch = searchText ?? state.value?.searchText ?? '';
    final currentLowStockOnly =
        lowStockOnly ?? state.value?.lowStockOnly ?? false;

    final items = await repository.getInventory(search: currentSearch);

    return InventoryState(
      items: _filterLowStock(items, currentLowStockOnly),
      searchText: currentSearch,
      lowStockOnly: currentLowStockOnly,
    );
  }

  Future<void> loadInventory() async {
    final previousState = state.value;

    state = await AsyncValue.guard(
      () => _loadState(
        searchText: previousState?.searchText,
        lowStockOnly: previousState?.lowStockOnly,
      ),
    );
  }

  Future<void> search(String value) async {
    final currentLowStockOnly = state.value?.lowStockOnly ?? false;

    state = await AsyncValue.guard(
      () => _loadState(searchText: value, lowStockOnly: currentLowStockOnly),
    );
  }

  Future<void> setLowStockOnly(bool value) async {
    final currentSearch = state.value?.searchText ?? '';

    state = await AsyncValue.guard(
      () => _loadState(searchText: currentSearch, lowStockOnly: value),
    );
  }

  Future<bool> increaseStock({
    required String productId,
    required int quantity,
  }) async {
    final repository = ref.read(inventoryRepositoryProvider);

    try {
      await repository.increaseStock(productId: productId, quantity: quantity);

      final refreshedState = await _loadState();

      state = AsyncValue.data(refreshedState);

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);

      return false;
    }
  }

  Future<bool> decreaseStock({
    required String productId,
    required int quantity,
  }) async {
    final repository = ref.read(inventoryRepositoryProvider);

    try {
      await repository.decreaseStock(productId: productId, quantity: quantity);

      final refreshedState = await _loadState();

      state = AsyncValue.data(refreshedState);

      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);

      return false;
    }
  }

  List<InventoryItem> _filterLowStock(
    List<InventoryItem> items,
    bool lowStockOnly,
  ) {
    if (!lowStockOnly) {
      return items;
    }

    return items
        .where((item) => item.stockQuantity <= lowStockThreshold)
        .toList();
  }
}
