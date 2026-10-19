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
    this.selectedCategory,
    this.categories = const [],
    this.categoryCounts = const {},
  });

  final List<InventoryItem> items;
  final String searchText;
  final bool lowStockOnly;
  final String? selectedCategory;
  final List<String> categories;
  final Map<String, int> categoryCounts;
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
    Object? category = _keep,
  }) async {
    final repository = ref.read(inventoryRepositoryProvider);

    final currentSearch = searchText ?? state.value?.searchText ?? '';
    final currentLowStockOnly =
        lowStockOnly ?? state.value?.lowStockOnly ?? false;
    final currentCategory = identical(category, _keep)
        ? state.value?.selectedCategory
        : category as String?;

    final items = _filterLowStock(
      await repository.getInventory(search: currentSearch),
      currentLowStockOnly,
    );

    final counts = <String, int>{};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    final categories = counts.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    // A category that no longer has items falls back to "All".
    final selected = counts.containsKey(currentCategory)
        ? currentCategory
        : null;

    return InventoryState(
      items: selected == null
          ? items
          : items.where((item) => item.category == selected).toList(),
      searchText: currentSearch,
      lowStockOnly: currentLowStockOnly,
      selectedCategory: selected,
      categories: categories,
      categoryCounts: counts,
    );
  }

  static const Object _keep = Object();

  Future<void> selectCategory(String? category) async {
    state = await AsyncValue.guard(() => _loadState(category: category));
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
