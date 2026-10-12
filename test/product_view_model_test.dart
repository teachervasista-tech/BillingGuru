import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/features/products/data/models/product.dart';
import 'package:billing_guru/features/products/data/repositories/product_repository.dart';
import 'package:billing_guru/features/products/data/services/product_local_service.dart';
import 'package:billing_guru/features/products/presentation/view_models/product_view_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeProductRepository extends ProductRepository {
  FakeProductRepository()
    : super(localService: ProductLocalService(database: AppDatabase.instance));

  @override
  Future<List<Product>> searchProducts(String query, {String? category}) async {
    return [
      Product(
        id: 'p-1',
        shortCode: 'COF001',
        barcode: '890000000001',
        name: 'Coffee',
        category: category ?? 'Beverages',
        priceCents: 299,
        taxRate: 19,
        stockQuantity: 12,
      ),
    ];
  }

  @override
  Future<List<Product>> getInactiveProducts({String search = ''}) async {
    return const [];
  }

  @override
  Future<List<String>> getActiveCategories() async {
    return const ['Beverages', 'Food'];
  }

  @override
  Future<Map<String, int>> getActiveCategoryCounts() async {
    return const {'Beverages': 1, 'Food': 2};
  }
}

void main() {
  test('setShowInactive keeps the selected category active', () async {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith(
          (ref) => FakeProductRepository(),
        ),
      ],
    );

    final notifier = container.read(productViewModelProvider.notifier);
    notifier.state = AsyncValue.data(
      const ProductState(
        products: [
          Product(
            id: 'p-1',
            shortCode: 'COF001',
            barcode: '890000000001',
            name: 'Coffee',
            category: 'Beverages',
            priceCents: 299,
            taxRate: 19,
            stockQuantity: 12,
          ),
        ],
        inactiveProducts: [],
        categories: ['Beverages', 'Food'],
        categoryCounts: {'Beverages': 1, 'Food': 2},
        searchText: '',
        selectedCategory: 'Beverages',
        showInactive: false,
      ),
    );

    await notifier.setShowInactive(true);

    expect(
      container.read(productViewModelProvider).value?.selectedCategory,
      equals('Beverages'),
    );
    expect(
      container.read(productViewModelProvider).value?.showInactive,
      isTrue,
    );
  });

  test('product-only reload preserves catalog metadata', () async {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith(
          (ref) => FakeProductRepository(),
        ),
      ],
    );

    final notifier = container.read(productViewModelProvider.notifier);
    notifier.state = AsyncValue.data(
      const ProductState(
        categories: ['Beverages', 'Food'],
        categoryCounts: {'Beverages': 1, 'Food': 2},
      ),
    );

    await notifier.loadProducts(includeCatalogMeta: false);

    final productState = container.read(productViewModelProvider).value!;
    expect(productState.products, hasLength(1));
    expect(productState.categories, ['Beverages', 'Food']);
    expect(productState.categoryCounts, {'Beverages': 1, 'Food': 2});
  });
}
