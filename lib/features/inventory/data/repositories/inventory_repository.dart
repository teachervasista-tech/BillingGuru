import '../../../checkout/domain/payment.dart';
import '../models/inventory_item.dart';
import '../services/inventory_local_service.dart';

class InventoryRepository {
  InventoryRepository({required this.localService});

  final InventoryLocalService localService;

  Future<List<InventoryItem>> getInventory({
    String search = '',
    bool includeInactive = false,
  }) {
    return localService.getInventory(
      search: search,
      includeInactive: includeInactive,
    );
  }

  Future<void> increaseStock({
    required String productId,
    required int quantity,
    int? unitCostCents,
    String? supplier,
    bool recordExpense = false,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) {
    return localService.increaseStock(
      productId: productId,
      quantity: quantity,
      unitCostCents: unitCostCents,
      supplier: supplier,
      recordExpense: recordExpense,
      paymentMethod: paymentMethod,
    );
  }

  Future<void> decreaseStock({
    required String productId,
    required int quantity,
  }) {
    return localService.decreaseStock(productId: productId, quantity: quantity);
  }
}
