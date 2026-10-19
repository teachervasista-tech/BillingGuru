import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tax/tax_rate_provider.dart';
import '../../../products/data/models/product.dart';
import '../../domain/cart_item.dart';

final cartProvider = NotifierProvider<CartViewModel, List<CartItem>>(
  CartViewModel.new,
);

class CartViewModel extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() {
    return const [];
  }

  void addProduct(Product product) {
    final existingIndex = state.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex == -1) {
      state = [...state, CartItem(product: product, quantity: 1)];
      return;
    }

    final items = [...state];
    final existingItem = items[existingIndex];

    if (existingItem.quantity >= product.stockQuantity) return;

    items[existingIndex] = existingItem.copyWith(
      quantity: existingItem.quantity + 1,
    );
    state = items;
  }

  void increaseQuantity(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    final item = state[index];
    if (item.quantity >= item.product.stockQuantity) return;

    final items = [...state];
    items[index] = item.copyWith(quantity: item.quantity + 1);
    state = items;
  }

  void decreaseQuantity(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);
    if (index == -1) return;

    final item = state[index];
    if (item.quantity <= 1) {
      removeProduct(productId);
      return;
    }

    final items = [...state];
    items[index] = item.copyWith(quantity: item.quantity - 1);
    state = items;
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = const [];
  }

  int get itemCount => state.fold(0, (total, item) => total + item.quantity);

  int get subtotalCents =>
      state.fold(0, (total, item) => total + item.totalCents);

  int get taxCents => subtotalCents * ref.read(defaultTaxRateProvider) ~/ 100;

  int get totalCents => subtotalCents + taxCents;
}
