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
  }) {
    return localService.getSales(search: search, range: range);
  }

  Future<SaleSummary?> getSaleById(String saleId) {
    return localService.getSaleById(saleId);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) {
    return localService.getSaleItems(saleId);
  }
}
