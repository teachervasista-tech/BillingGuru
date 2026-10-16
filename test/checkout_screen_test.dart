import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/features/cart/presentation/view_models/cart_view_model.dart';
import 'package:billing_guru/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:billing_guru/features/products/data/models/product.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkout shows a receipt-style order summary', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(currencyProvider.notifier).loadCurrencyFromAsset();

    const product = Product(
      id: 'coffee',
      shortCode: 'COF001',
      barcode: '',
      name: 'Coffee beans',
      category: 'Beverages',
      priceCents: 1250,
      taxRate: 18,
      stockQuantity: 10,
    );
    final cart = container.read(cartProvider.notifier);
    cart.addProduct(product);
    cart.addProduct(product);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: CheckoutScreen()),
      ),
    );

    expect(find.text('Order summary'), findsOneWidget);
    expect(find.textContaining('Date and time:'), findsOneWidget);
    expect(find.text('Coffee beans'), findsOneWidget);
    expect(find.textContaining('2 x'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Tax'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
  });
}
