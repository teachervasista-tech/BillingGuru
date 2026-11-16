import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/database_provider.dart';
import 'auto_backup_service.dart';
import 'backup_service.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(database: ref.watch(appDatabaseProvider));
});

final autoBackupServiceProvider = Provider<AutoBackupService>((ref) {
  return AutoBackupService(backup: ref.watch(backupServiceProvider));
});

/// Latest automatic backup outcome; invalidate after a run or folder change.
final autoBackupStatusProvider = FutureProvider<AutoBackupStatus>((ref) {
  return ref.watch(autoBackupServiceProvider).status();
});
