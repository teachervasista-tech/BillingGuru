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
}
