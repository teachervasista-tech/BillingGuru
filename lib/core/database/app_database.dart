import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'migrations.dart';

class AppDatabase {
  AppDatabase._internal() : _factory = null, _path = null;

  /// Creates a database bound to an explicit [factory] and [path], e.g.
  /// `AppDatabase.forTesting(databaseFactoryFfi, inMemoryDatabasePath)`.
  AppDatabase.forTesting(DatabaseFactory factory, String path)
    : _factory = factory,
      _path = path;

  static final AppDatabase instance = AppDatabase._internal();

  static const String databaseName = 'pos_billing.db';

  /// Bump together with a new entry in [appMigrations].
  static int get schemaVersion => latestSchemaVersion;

  final DatabaseFactory? _factory;
  final String? _path;

  Database? _database;

  DatabaseFactory get _dbFactory => _factory ?? databaseFactory;

  /// Absolute path of the database file (used by backup/restore).
  Future<String> get databasePath async {
    final explicit = _path;
    if (explicit != null) return explicit;
    return join(await _dbFactory.getDatabasesPath(), databaseName);
  }

  Future<Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null && existingDatabase.isOpen) {
      return existingDatabase;
    }
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    return _dbFactory.openDatabase(
      await databasePath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        singleInstance: _path == null,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onOpen: _insertInitialProducts,
      ),
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Fresh installs build the baseline (v2) schema, then run every later
  /// migration, so new and upgraded databases always end up identical.
  Future<void> _onCreate(Database db, int version) async {
    await db.transaction((txn) async {
      await createBaselineSchema(txn);
      await runMigrations(txn, from: baselineSchemaVersion, to: version);
    });
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((txn) async {
      await runMigrations(txn, from: oldVersion, to: newVersion);
    });
  }

  Future<void> _insertInitialProducts(Database db) async {
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products',
    );

    final count = countResult.first['count'] as int? ?? 0;

    if (count > 0) {
      return;
    }

    await db.insert('products', {
      'id': 'Test-001',
      'short_code': 'COF001',
      'barcode': '890000000001',
      'name': 'TestCoffee',
      'category': 'TestBeverages',
      'price_cents': 299,
      'image_path': null,
      'tax_rate': 19,
      'stock_quantity': 50,
      'is_active': 1,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> close() async {
    final database = _database;

    if (database != null && database.isOpen) {
      await database.close();
    }

    _database = null;
  }

  /// Replaces the database file with [source] (e.g. from a backup). The next
  /// access reopens it and runs any pending migrations.
  Future<void> replaceWith(File source) async {
    final path = await databasePath;
    await close();
    for (final suffix in ['', '-wal', '-shm', '-journal']) {
      final file = File('$path$suffix');
      if (await file.exists()) await file.delete();
    }
    await source.copy(path);
    await database;
  }

  /// Writes a consistent copy of the open database to [targetPath].
  Future<void> snapshotTo(String targetPath) async {
    final db = await database;
    final escaped = targetPath.replaceAll("'", "''");
    await db.execute("VACUUM INTO '$escaped'");
  }

  Future<void> deleteDatabaseForDevelopment() async {
    final path = await databasePath;
    await close();
    await _dbFactory.deleteDatabase(path);
  }
}
