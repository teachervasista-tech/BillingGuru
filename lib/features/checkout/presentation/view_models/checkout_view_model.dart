import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../cart/domain/cart_item.dart';
import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../../../sales/presentation/view_models/sales_view_model.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../domain/payment.dart';
import '../../domain/sale.dart';
import '../../domain/sale_item.dart';

final checkoutRepositoryProvider = Provider<CheckoutRepository>((ref) {
  return CheckoutRepository(database: AppDatabase.instance);
});

final checkoutViewModelProvider =
    NotifierProvider<CheckoutViewModel, CheckoutState>(CheckoutViewModel.new);

class CheckoutState {
  const CheckoutState({
    this.isSaving = false,
    this.isCompleted = false,
    this.errorMessage,
    this.lastSale,
  });

  final bool isSaving;
  final bool isCompleted;
  final String? errorMessage;
  final Sale? lastSale;

  CheckoutState copyWith({
    bool? isSaving,
    bool? isCompleted,
    String? errorMessage,
    Sale? lastSale,
    bool clearError = false,
  }) {
    return CheckoutState(
      isSaving: isSaving ?? this.isSaving,
      isCompleted: isCompleted ?? this.isCompleted,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      lastSale: lastSale ?? this.lastSale,
    );
  }
}

class CheckoutViewModel extends Notifier<CheckoutState> {
  static const Uuid _uuid = Uuid();

  @override
  CheckoutState build() {
    return const CheckoutState();
  }

  Future<void> completeCashSale(WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = state.copyWith(errorMessage: 'The cart is empty.');
      return;
    }

    await _completeSale(
      ref: ref,
      cart: cart,
      paymentMethod: PaymentMethod.cash,
    );
  }

  Future<void> completeCardSale(WidgetRef ref) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = state.copyWith(errorMessage: 'The cart is empty.');
      return;
    }

    await _completeSale(
      ref: ref,
      cart: cart,
      paymentMethod: PaymentMethod.card,
    );
  }

  Future<void> _completeSale({
    required WidgetRef ref,
    required List<CartItem> cart,
    required PaymentMethod paymentMethod,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final saleId = _uuid.v4();

      final saleItems = cart.map((cartItem) {
        return SaleItem(
          id: _uuid.v4(),
          saleId: saleId,
          productId: cartItem.product.id,
          quantity: cartItem.quantity,
          unitPriceCents: cartItem.product.priceCents,
          totalCents: cartItem.totalCents,
        );
      }).toList();

      final subtotalCents = cart.fold<int>(
        0,
        (sum, item) => sum + item.totalCents,
      );

      final taxCents = cart.fold<int>(
        0,
        (sum, item) => sum + (item.totalCents * item.product.taxRate ~/ 100),
      );

      final sale = Sale(
        id: saleId,
        invoiceNumber: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        items: saleItems,
        subtotalCents: subtotalCents,
        discountCents: 0,
        taxCents: taxCents,
        totalCents: subtotalCents + taxCents,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        syncStatus: 'pending',
      );

      final repository = ref.read(checkoutRepositoryProvider);
      await repository.saveSale(sale);

      ref.invalidate(salesViewModelProvider);

      ref.read(cartProvider.notifier).clear();

      state = state.copyWith(
        isSaving: false,
        isCompleted: true,
        lastSale: sale,
      );
    } catch (error) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Unable to save the sale: $error',
      );
    }
  }

  void reset() {
    state = const CheckoutState();
  }
}
