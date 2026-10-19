import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/features/products/data/models/product.dart';
import 'package:billing_guru/features/products/data/repositories/product_repository.dart';
import 'package:billing_guru/features/products/data/services/product_local_service.dart';
import 'package:billing_guru/features/products/presentation/screens/products_screen.dart';
import 'package:billing_guru/features/products/presentation/view_models/product_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeProductRepository extends ProductRepository {
  _FakeProductRepository()
    : super(localService: ProductLocalService(database: AppDatabase.instance));

  static const _products = [
    Product(
      id: 'coffee',
      shortCode: 'COF001',
      barcode: '',
      name: 'Coffee beans',
      category: 'Beverages',
      priceCents: 299,
      taxRate: 19,
      stockQuantity: 12,
    ),
    Product(
      id: 'pasta',
      shortCode: 'PAS001',
      barcode: '',
      name: 'Pasta',
      category: 'Food',
      priceCents: 199,
      taxRate: 19,
      stockQuantity: 8,
    ),
  ];

  @override
  Future<List<Product>> searchProducts(String query, {String? category}) async {
    return _products.where((product) {
      final matchesCategory = category == null || product.category == category;
      final matchesSearch =
          query.isEmpty ||
          product.name.toLowerCase().contains(query.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
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
    return const {'Beverages': 1, 'Food': 1};
  }
}

void main() {
  testWidgets('category tab filters products to its category', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWith(
          (ref) => _FakeProductRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ProductsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Coffee beans'), findsOneWidget);
    expect(find.text('Pasta'), findsOneWidget);
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.byTooltip('Edit product'), findsNWidgets(2));

    await tester.tap(find.text('Food (1)'));
    await tester.pumpAndSettle();

    expect(
      container.read(productViewModelProvider).value?.selectedCategory,
      'Food',
    );
    expect(find.text('Coffee beans'), findsNothing);
    expect(find.text('Pasta'), findsOneWidget);
  });
}
