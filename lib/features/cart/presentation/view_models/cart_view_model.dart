import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/cart_item.dart';
import '../../../products/data/models/product.dart';

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

    final updatedItems = [...state];
    final existingItem = updatedItems[existingIndex];

    if (existingItem.quantity >= product.stockQuantity) {
      return;
    }

    updatedItems[existingIndex] = existingItem.copyWith(
      quantity: existingItem.quantity + 1,
    );

    state = updatedItems;
  }

  void increaseQuantity(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);

    if (index == -1) {
      return;
    }

    final item = state[index];

    if (item.quantity >= item.product.stockQuantity) {
      return;
    }

    final updatedItems = [...state];

    updatedItems[index] = item.copyWith(quantity: item.quantity + 1);

    state = updatedItems;
  }

  void decreaseQuantity(String productId) {
    final index = state.indexWhere((item) => item.product.id == productId);

    if (index == -1) {
      return;
    }

    final item = state[index];

    if (item.quantity <= 1) {
      removeProduct(productId);
      return;
    }

    final updatedItems = [...state];

    updatedItems[index] = item.copyWith(quantity: item.quantity - 1);

    state = updatedItems;
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clear() {
    state = const [];
  }

  int get itemCount {
    return state.fold(0, (total, item) => total + item.quantity);
  }

  int get subtotalCents {
    return state.fold(0, (total, item) => total + item.totalCents);
  }

  int get taxCents {
    return state.fold(0, (total, item) {
      return total + item.totalCents * item.product.taxRate ~/ 100;
    });
  }

  int get totalCents {
    return subtotalCents + taxCents;
  }
}
