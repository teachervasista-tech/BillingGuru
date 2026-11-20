import 'package:billing_guru/features/cart/presentation/view_models/cart_view_model.dart';
import 'package:billing_guru/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:billing_guru/features/products/data/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);

  testWidgets('Print receipt saves once, clears the cart and returns to PoS', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = createTestDatabase();
    addTearDown(database.close);
    final db = await tester.runAsync(() => database.database);
    await tester.runAsync(
      () => db!.insert('products', {
        'id': 'tea',
        'short_code': 'TEA',
        'name': 'Tea',
        'price_cents': 200,
        'tax_rate': 10,
        'stock_quantity': 20,
        'cost_price_cents': 80,
      }),
    );
    final container = (await tester.runAsync(
      () => createTestContainer(database: database, user: testAdmin),
    ))!;
    addTearDown(container.dispose);

    container
        .read(cartProvider.notifier)
        .addProduct(
          const Product(
            id: 'tea',
            shortCode: 'TEA',
            barcode: '',
            name: 'Tea',
            category: '',
            priceCents: 200,
            taxRate: 10,
            stockQuantity: 20,
          ),
        );

    final router = GoRouter(
      initialLocation: '/checkout',
      routes: [
        GoRoute(path: '/checkout', builder: (_, _) => const CheckoutScreen()),
        GoRoute(path: '/pos', builder: (_, _) => const Text('PoS screen')),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // Saving the sale and loading the receipt runs real async work, so let
    // it finish outside the fake clock, pumping frames as it goes.
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)),
        );
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    await tester.tap(find.text('Pay and print receipt'));
    await settle();

    // The print dialog is open (printer list may still be loading); close it
    // without printing.
    expect(find.text('Close'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await settle();

    expect(find.text('PoS screen'), findsOneWidget);
    expect(container.read(cartProvider), isEmpty);
    final rows = await tester.runAsync(
      () => db!.rawQuery('SELECT COUNT(*) AS n FROM sales'),
    );
    expect(rows!.single['n'], 1);
  });
}
