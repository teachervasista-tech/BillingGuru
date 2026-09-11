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
  }) {
    return localService.increaseStock(productId: productId, quantity: quantity);
  }

  Future<void> decreaseStock({
    required String productId,
    required int quantity,
  }) {
    return localService.decreaseStock(productId: productId, quantity: quantity);
  }
}
