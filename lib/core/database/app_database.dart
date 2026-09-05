import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(databaseDirectory, 'pos_billing.db');

    return openDatabase(
      databasePath,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createTables(db);
        await _insertDemoProducts(db);
      },
    );
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        barcode TEXT NOT NULL UNIQUE,
        name TEXT NOT NULL,
        price_cents INTEGER NOT NULL,
        tax_rate INTEGER NOT NULL,
        stock_quantity INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoice_number TEXT NOT NULL UNIQUE,
        subtotal_cents INTEGER NOT NULL,
        discount_cents INTEGER NOT NULL,
        tax_cents INTEGER NOT NULL,
        total_cents INTEGER NOT NULL,
        payment_method TEXT NOT NULL,
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        total_cents INTEGER NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');

    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  Future<void> _insertDemoProducts(Database db) async {
    final products = [
      {
        'id': 'p-001',
        'barcode': '890000000001',
        'name': 'Coffee',
        'price_cents': 299,
        'tax_rate': 19,
        'stock_quantity': 50,
        'is_active': 1,
      },
      {
        'id': 'p-002',
        'barcode': '890000000002',
        'name': 'Tea',
        'price_cents': 199,
        'tax_rate': 19,
        'stock_quantity': 40,
        'is_active': 1,
      },
      {
        'id': 'p-003',
        'barcode': '890000000003',
        'name': 'Sandwich',
        'price_cents': 499,
        'tax_rate': 7,
        'stock_quantity': 20,
        'is_active': 1,
      },
      {
        'id': 'p-004',
        'barcode': '890000000004',
        'name': 'Water',
        'price_cents': 149,
        'tax_rate': 19,
        'stock_quantity': 100,
        'is_active': 1,
      },
    ];

    for (final product in products) {
      await db.insert(
        'products',
        product,
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  Future<void> deleteDatabaseForDevelopment() async {
    final databaseDirectory = await getDatabasesPath();
    final databasePath = join(databaseDirectory, 'pos_billing.db');

    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    await deleteDatabase(databasePath);
  }
}
