import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// Persists runtime settings as string key/value pairs.
abstract class SettingsStore {
  Future<Map<String, String>> readAll();

  Future<void> writeAll(Map<String, String> values);
}

/// Stores settings in the `app_settings` table so they are part of the
/// database file (and therefore of backups).
class DatabaseSettingsStore implements SettingsStore {
  DatabaseSettingsStore(this._database);

  final AppDatabase _database;

  @override
  Future<Map<String, String>> readAll() async {
    final db = await _database.database;
    final rows = await db.query('app_settings');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }

  @override
  Future<void> writeAll(Map<String, String> values) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (final entry in values.entries) {
        await txn.insert('app_settings', {
          'key': entry.key,
          'value': entry.value,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  }
}

/// Non-persistent store for tests and previews.
class InMemorySettingsStore implements SettingsStore {
  InMemorySettingsStore([Map<String, String>? initial])
    : values = {...?initial};

  final Map<String, String> values;

  @override
  Future<Map<String, String>> readAll() async => {...values};

  @override
  Future<void> writeAll(Map<String, String> newValues) async {
    values.addAll(newValues);
  }
}
