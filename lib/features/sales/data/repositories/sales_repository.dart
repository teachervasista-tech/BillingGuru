import '../../../checkout/domain/sale_item.dart';
import '../../domain/sales_period.dart';
import '../models/sale_summary.dart';
import '../services/sales_local_service.dart';

class SalesRepository {
  SalesRepository({required this.localService});

  final SalesLocalService localService;

  Future<List<SaleSummary>> getSales({
    String search = '',
    SalesDateRange? range,
    String? customerId,
  }) {
    return localService.getSales(
      search: search,
      range: range,
      customerId: customerId,
    );
  }

  Future<void> voidSale(String saleId, {String? reason}) =>
      localService.voidSale(saleId, reason: reason);

  Future<void> returnItems(
    String saleId,
    Map<String, int> quantities, {
    String? reason,
  }) => localService.returnItems(saleId, quantities, reason: reason);

  Future<SaleSummary?> getSaleById(String saleId) {
    return localService.getSaleById(saleId);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) {
    return localService.getSaleItems(saleId);
  }
}
