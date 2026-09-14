import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/product.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/services/product_local_service.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    localService: ProductLocalService(database: AppDatabase.instance),
  );
});

final productViewModelProvider =
    AsyncNotifierProvider<ProductViewModel, ProductState>(ProductViewModel.new);

class ProductState {
  const ProductState({
    this.products = const [],
    this.inactiveProducts = const [],
    this.categories = const [],
    this.categoryCounts = const {},
    this.searchText = '',
    this.selectedCategory,
    this.showInactive = false,
  });

  final List<Product> products;
  final List<Product> inactiveProducts;
  final List<String> categories;
  final Map<String, int> categoryCounts;
  final String searchText;
  final String? selectedCategory;
  final bool showInactive;

  List<Product> get visibleProducts {
    return showInactive ? inactiveProducts : products;
  }

  ProductState copyWith({
    List<Product>? products,
    List<Product>? inactiveProducts,
    List<String>? categories,
    Map<String, int>? categoryCounts,
    String? searchText,
    String? selectedCategory,
    bool clearSelectedCategory = false,
    bool? showInactive,
  }) {
    return ProductState(
      products: products ?? this.products,
      inactiveProducts: inactiveProducts ?? this.inactiveProducts,
      categories: categories ?? this.categories,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      searchText: searchText ?? this.searchText,
      selectedCategory: clearSelectedCategory
          ? null
          : selectedCategory ?? this.selectedCategory,
      showInactive: showInactive ?? this.showInactive,
    );
  }
}

class ProductViewModel extends AsyncNotifier<ProductState> {
  @override
  Future<ProductState> build() async {
    return _loadState();
  }

  Future<ProductState> _loadState({
    String? searchText,
    String? selectedCategory,
    bool? showInactive,
  }) async {
    final repository = ref.read(productRepositoryProvider);

    final currentSearch = searchText ?? '';
    final currentCategory = selectedCategory;
    final currentShowInactive = showInactive ?? false;

    final activeProducts = await repository.searchProducts(
      currentSearch,
      category: currentCategory,
    );

    final inactiveProducts = await repository.getInactiveProducts(
      search: currentSearch,
    );

    final categories = await repository.getActiveCategories();
    final categoryCounts = await repository.getActiveCategoryCounts();

    return ProductState(
      products: activeProducts,
      inactiveProducts: inactiveProducts,
      categories: categories,
      categoryCounts: categoryCounts,
      searchText: currentSearch,
      selectedCategory: currentCategory,
      showInactive: currentShowInactive,
    );
  }

  Future<void> loadProducts() async {
    final currentState = state.value;

    state = await AsyncValue.guard(
      () => _loadState(
        searchText: currentState?.searchText,
        selectedCategory: currentState?.selectedCategory,
        showInactive: currentState?.showInactive,
      ),
    );
  }

  Future<void> search(String value) async {
    final currentState = state.value;

    state = await AsyncValue.guard(
      () => _loadState(
        searchText: value,
        selectedCategory: currentState?.selectedCategory,
        showInactive: currentState?.showInactive,
      ),
    );
  }

  Future<void> selectCategory(String? category) async {
    final currentState = state.value;

    state = await AsyncValue.guard(
      () => _loadState(
        searchText: currentState?.searchText,
        selectedCategory: category,
        showInactive: currentState?.showInactive,
      ),
    );
  }

  Future<void> clearSearch() {
    return search('');
  }

  Future<void> setShowInactive(bool value) async {
    final currentSearch = state.value?.searchText ?? '';

    state = await AsyncValue.guard(
      () => _loadState(searchText: currentSearch, showInactive: value),
    );
  }

  Future<bool> addProduct({
    required String barcode,
    required String name,
    required String category,
    required int priceCents,
    required int taxRate,
    required int stockQuantity,
  }) async {
    final repository = ref.read(productRepositoryProvider);

    final product = Product(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      barcode: barcode.trim(),
      name: name.trim(),
      category: category.trim(),
      priceCents: priceCents,
      taxRate: taxRate,
      stockQuantity: stockQuantity,
    );

    try {
      await repository.addProduct(product);
      await _reloadAfterMutation();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> updateProduct({
    required Product product,
    required String barcode,
    required String name,
    required String category,
    required int priceCents,
    required int taxRate,
    required int stockQuantity,
  }) async {
    final repository = ref.read(productRepositoryProvider);

    final updatedProduct = product.copyWith(
      barcode: barcode.trim(),
      name: name.trim(),
      category: category.trim(),
      priceCents: priceCents,
      taxRate: taxRate,
      stockQuantity: stockQuantity,
    );

    try {
      await repository.updateProduct(updatedProduct);
      await _reloadAfterMutation();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> deactivateProduct(String productId) async {
    final repository = ref.read(productRepositoryProvider);

    try {
      await repository.deactivateProduct(productId);
      await _reloadAfterMutation();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<bool> activateProduct(String productId) async {
    final repository = ref.read(productRepositoryProvider);

    try {
      await repository.activateProduct(productId);
      await _reloadAfterMutation();
      return true;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      return false;
    }
  }

  Future<void> _reloadAfterMutation() async {
    final currentState = state.value;

    final refreshedState = await _loadState(
      searchText: currentState?.searchText,
      showInactive: currentState?.showInactive,
    );

    state = AsyncValue.data(refreshedState);
  }
}
