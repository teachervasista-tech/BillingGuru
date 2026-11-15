import 'dart:io';

import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/database/migrations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<Set<String>> _tables(Database db) async {
  final rows = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  );
  return rows.map((r) => r['name'] as String).toSet();
}

Future<Map<String, Set<String>>> _schema(Database db) async {
  final result = <String, Set<String>>{};
  for (final table in await _tables(db)) {
    if (table.startsWith('sqlite_') || table == 'android_metadata') continue;
    final cols = await db.rawQuery('PRAGMA table_info($table)');
    result[table] = cols.map((c) => c['name'] as String).toSet();
  }
  return result;
}

void main() {
  sqfliteFfiInit();
  final factory = databaseFactoryFfiNoIsolate;
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bg_migration_');
  });
  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  test('fresh install reaches the latest version with all tables', () async {
    final appDb = AppDatabase.forTesting(factory, inMemoryDatabasePath);
    final db = await appDb.database;

    expect(await db.getVersion(), latestSchemaVersion);
    expect(
      await _tables(db),
      containsAll([
        'products',
        'sales',
        'sale_items',
        'stock_movements',
        'app_settings',
      ]),
    );
    await appDb.close();
  });

  test('legacy v2 database without stock_movements is upgraded '
      'and keeps its data', () async {
    final path = p.join(tempDir.path, 'legacy.db');

    // Simulate a v2 database created before stock_movements existed.
    final legacy = await factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, _) async {
          await createBaselineSchema(db);
          await db.insert('products', {
            'id': 'p1',
            'short_code': 'P1',
            'name': 'Tea',
            'price_cents': 100,
            'tax_rate': 5,
            'stock_quantity': 7,
          });
          await db.insert('sales', {
            'id': 's1',
            'invoice_number': 'INV-1',
            'subtotal_cents': 100,
            'discount_cents': 0,
            'tax_cents': 5,
            'total_cents': 105,
            'payment_method': 'cash',
            'created_at': '2026-11-01T10:00:00.000',
            'sync_status': 'pending',
          });
        },
      ),
    );
    expect(await _tables(legacy), isNot(contains('stock_movements')));
    await legacy.close();

    final upgraded = AppDatabase.forTesting(factory, path);
    final db = await upgraded.database;

    expect(await db.getVersion(), latestSchemaVersion);
    expect(await _tables(db), containsAll(['stock_movements', 'app_settings']));
    final product = (await db.query('products', where: "id = 'p1'")).single;
    expect(product['stock_quantity'], 7);
    expect((await db.query('sales')).length, 1);

    // Upgraded schema must match a fresh install exactly.
    final fresh = AppDatabase.forTesting(factory, inMemoryDatabasePath);
    expect(await _schema(db), await _schema(await fresh.database));

    await upgraded.close();
    await fresh.close();
  });
}
