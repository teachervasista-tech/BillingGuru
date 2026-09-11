import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/database/app_database.dart';
import '../../data/models/dashboard_summary.dart';
import '../../data/repositories/dashboard_repository.dart';
import '../../data/services/dashboard_local_service.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(
    localService: DashboardLocalService(database: AppDatabase.instance),
  );
});

final dashboardViewModelProvider =
    AsyncNotifierProvider<DashboardViewModel, DashboardSummary>(
      DashboardViewModel.new,
    );

class DashboardViewModel extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() async {
    return ref.read(dashboardRepositoryProvider).getSummary();
  }

  Future<void> loadDashboard() async {
    final repository = ref.read(dashboardRepositoryProvider);

    state = await AsyncValue.guard(repository.getSummary);
  }
}
