import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Single injection point for the database. Override in tests with an
/// in-memory [AppDatabase] (see `AppDatabase.forTesting`).
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});
