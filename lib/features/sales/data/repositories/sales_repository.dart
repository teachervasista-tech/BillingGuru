import '../models/sale_summary.dart';
import '../services/sales_local_service.dart';

class SalesRepository {
  SalesRepository({required this.localService});

  final SalesLocalService localService;

  Future<List<SaleSummary>> getSales({String search = ''}) {
    return localService.getSales(search: search);
  }

  Future<SaleSummary?> getSaleById(String saleId) {
    return localService.getSaleById(saleId);
  }
}
