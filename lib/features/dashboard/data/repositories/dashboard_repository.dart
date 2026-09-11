import '../models/dashboard_summary.dart';
import '../services/dashboard_local_service.dart';

class DashboardRepository {
  DashboardRepository({required this.localService});

  final DashboardLocalService localService;

  Future<DashboardSummary> getSummary() {
    return localService.getSummary();
  }
}
