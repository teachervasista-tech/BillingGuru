import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/tax/tax_rate_provider.dart';
import '../../../cart/domain/cart_item.dart';
import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../../../sales/presentation/view_models/sales_view_model.dart';
import '../../../dashboard/presentation/view_models/dashboard_view_model.dart';
import '../../../reports/presentation/providers/report_providers.dart';
import '../../data/repositories/checkout_repository.dart';
import '../../domain/invoice_sequence.dart';
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

  // The sale already saved for the current cart, so printing or paying again
  // for the same cart never records a duplicate invoice.
  Sale? _recordedSale;
  String? _recordedCartSignature;

  @override
  CheckoutState build() {
    ref.listen(cartProvider, (_, cart) {
      if (cart.isEmpty) {
        _recordedSale = null;
        _recordedCartSignature = null;
      }
    });
    return const CheckoutState();
  }

  String _cartSignature(List<CartItem> cart) {
    return cart
        .map(
          (item) =>
              '${item.product.id}:${item.quantity}:${item.product.priceCents}',
        )
        .join('|');
  }

  /// Saves the cart as a sale the first time it is called for a given cart
  /// and returns the same sale on later calls.
  Future<Sale> recordSale(
    List<CartItem> cart,
    PaymentMethod paymentMethod,
  ) async {
    final signature = _cartSignature(cart);
    final existing = _recordedSale;
    if (existing != null && _recordedCartSignature == signature) {
      return existing;
    }

    final sale = await buildSale(cart, paymentMethod);
    await ref.read(checkoutRepositoryProvider).saveSale(sale);
    _recordedSale = sale;
    _recordedCartSignature = signature;

    ref.invalidate(dashboardViewModelProvider);
    ref.invalidate(salesViewModelProvider);
    ref.invalidate(reportProvider);
    return sale;
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

  Future<void> completeSale(WidgetRef ref, PaymentMethod paymentMethod) async {
    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      state = state.copyWith(errorMessage: 'The cart is empty.');
      return;
    }

    await _completeSale(ref: ref, cart: cart, paymentMethod: paymentMethod);
  }

  Future<Sale> buildSale(
    List<CartItem> cart,
    PaymentMethod paymentMethod,
  ) async {
    final now = DateTime.now();
    final reset = await ref.read(invoiceSequenceResetProvider.future);
    final invoiceNumber = await ref
        .read(checkoutRepositoryProvider)
        .nextInvoiceNumber(reset, now);
    final saleId = _uuid.v4();

    final saleItems = cart.map((cartItem) {
      return SaleItem(
        id: _uuid.v4(),
        saleId: saleId,
        productId: cartItem.product.id,
        productName: cartItem.product.name,
        quantity: cartItem.quantity,
        unitPriceCents: cartItem.product.priceCents,
        totalCents: cartItem.totalCents,
      );
    }).toList();

    final subtotalCents = cart.fold<int>(
      0,
      (sum, item) => sum + item.totalCents,
    );

    final taxCents = subtotalCents * ref.read(defaultTaxRateProvider) ~/ 100;

    return Sale(
      id: saleId,
      invoiceNumber: invoiceNumber,
      items: saleItems,
      subtotalCents: subtotalCents,
      discountCents: 0,
      taxCents: taxCents,
      totalCents: subtotalCents + taxCents,
      paymentMethod: paymentMethod,
      createdAt: now,
      syncStatus: 'pending',
    );
  }

  Future<void> _completeSale({
    required WidgetRef ref,
    required List<CartItem> cart,
    required PaymentMethod paymentMethod,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final sale = await recordSale(cart, paymentMethod);

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
