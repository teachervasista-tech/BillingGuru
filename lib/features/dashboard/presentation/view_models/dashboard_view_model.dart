import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/database_provider.dart';
import '../../../../core/settings/app_settings_provider.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/services/dashboard_local_service.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    localService: DashboardLocalService(
      database: ref.watch(appDatabaseProvider),
    ),
  );
});

final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, DashboardSummary>(
      DashboardViewModel.new,
    );

class DashboardViewModel extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    return _load();
  }

  Future<void> loadDashboard() async {
    state = await AsyncValue.guard(_load);
  }

  Future<DashboardSummary> _load() {
    return ref
        .read(dashboardRepositoryProvider)
        .getSummary(lowStockThreshold: ref.read(lowStockThresholdProvider));
  }
}
