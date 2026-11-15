import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/database/database_provider.dart';
import 'package:billing_guru/core/settings/app_settings_provider.dart';
import 'package:billing_guru/core/settings/settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// A fresh, migrated in-memory database (desktop FFI).
AppDatabase createTestDatabase() {
  sqfliteFfiInit();
  return AppDatabase.forTesting(
    databaseFactoryFfiNoIsolate,
    inMemoryDatabasePath,
  );
}

/// Container with settings kept in memory and (optionally) an in-memory DB.
/// Settings are loaded from the asset defaults plus [storedSettings].
Future<ProviderContainer> createTestContainer({
  Map<String, String>? storedSettings,
  AppDatabase? database,
  bool loadSettings = true,
}) async {
  final container = ProviderContainer(
    overrides: [
      settingsStoreProvider.overrideWithValue(
        InMemorySettingsStore(storedSettings),
      ),
      if (database != null) appDatabaseProvider.overrideWithValue(database),
    ],
  );
  if (loadSettings) {
    await container.read(appSettingsProvider.notifier).load();
  }
  return container;
}
