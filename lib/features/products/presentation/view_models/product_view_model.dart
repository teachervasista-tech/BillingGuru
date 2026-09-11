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
  const ProductState({this.products = const [], this.searchText = ''});

  final List<Product> products;
  final String searchText;

  ProductState copyWith({List<Product>? products, String? searchText}) {
    return ProductState(
      products: products ?? this.products,
      searchText: searchText ?? this.searchText,
    );
  }
}

class ProductViewModel extends AsyncNotifier<ProductState> {
  @override
  Future<ProductState> build() async {
    final repository = ref.read(productRepositoryProvider);
    final products = await repository.getAllProducts();

    return ProductState(products: products);
  }

  Future<void> loadProducts() async {
    final repository = ref.read(productRepositoryProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final products = await repository.getAllProducts();

      return ProductState(products: products);
    });
  }

  Future<void> search(String value) async {
    final repository = ref.read(productRepositoryProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final products = await repository.searchProducts(value);

      return ProductState(products: products, searchText: value);
    });
  }

  Future<void> clearSearch() {
    return search('');
  }

  Future<bool> addProduct({
    required String barcode,
    required String name,
    required int priceCents,
    required int taxRate,
    required int stockQuantity,
  }) async {
    final repository = ref.read(productRepositoryProvider);

    final product = Product(
      id: 'p-${DateTime.now().microsecondsSinceEpoch}',
      barcode: barcode.trim(),
      name: name.trim(),
      priceCents: priceCents,
      taxRate: taxRate,
      stockQuantity: stockQuantity,
    );

    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await repository.addProduct(product);

      final products = await repository.getAllProducts();

      return ProductState(products: products);
    });

    state = result;

    return result.hasValue;
  }

  Future<bool> updateProduct({
    required Product product,
    required String barcode,
    required String name,
    required int priceCents,
    required int taxRate,
    required int stockQuantity,
  }) async {
    final repository = ref.read(productRepositoryProvider);

    final updatedProduct = product.copyWith(
      barcode: barcode.trim(),
      name: name.trim(),
      priceCents: priceCents,
      taxRate: taxRate,
      stockQuantity: stockQuantity,
    );

    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await repository.updateProduct(updatedProduct);

      final products = await repository.getAllProducts();

      return ProductState(products: products);
    });

    state = result;

    return result.hasValue;
  }

  Future<bool> deactivateProduct(String productId) async {
    final repository = ref.read(productRepositoryProvider);

    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await repository.deactivateProduct(productId);

      final products = await repository.getAllProducts();

      return ProductState(products: products);
    });

    state = result;

    return result.hasValue;
  }

  Future<bool> activateProduct(String productId) async {
    final repository = ref.read(productRepositoryProvider);

    state = const AsyncLoading();

    final result = await AsyncValue.guard(() async {
      await repository.activateProduct(productId);

      final products = await repository.getAllProducts();

      return ProductState(products: products);
    });

    state = result;

    return result.hasValue;
  }
}
