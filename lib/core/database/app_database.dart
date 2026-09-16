import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const String _databaseName = 'pos_billing.db';
  static const int _databaseVersion = 1;

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null && existingDatabase.isOpen) {
      return existingDatabase;
    }

    _database = await _openDatabase();
    return _database!;
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await getDatabasesPath();

    final databasePath = join(databaseDirectory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      singleInstance: true,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureReferenceData(db);
      },
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createProductsTable(db);
    await _createSalesTable(db);
    await _createSaleItemsTable(db);
    await _createStockMovementsTable(db);
    await _insertInitialProducts(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.transaction((transaction) async {
      if (oldVersion < 2) {
        await transaction.execute('''
          ALTER TABLE products
          ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'
        ''');
      }

      if (oldVersion < 3) {
        await transaction.execute('''
          CREATE TABLE IF NOT EXISTS stock_movements (
            id TEXT PRIMARY KEY,
            product_id TEXT NOT NULL,
            movement_type TEXT NOT NULL,
            quantity INTEGER NOT NULL,
            reference_id TEXT,
            created_at TEXT NOT NULL,
            FOREIGN KEY (product_id)
              REFERENCES products (id)
          )
        ''');
      }
    });
  }

  Future<void> _createProductsTable(Database db) async {
    await db.execute('''
    CREATE TABLE products (
      id TEXT PRIMARY KEY,
      short_code TEXT NOT NULL UNIQUE,
      barcode TEXT NOT NULL UNIQUE,
      name TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'Other',
      price_cents INTEGER NOT NULL,
      tax_rate INTEGER NOT NULL,
      stock_quantity INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''');
  }

  Future<void> _createSalesTable(Database db) async {
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
  }

  Future<void> _createSaleItemsTable(Database db) async {
    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        product_id TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unit_price_cents INTEGER NOT NULL,
        total_cents INTEGER NOT NULL,
        FOREIGN KEY (sale_id)
          REFERENCES sales (id)
          ON DELETE CASCADE,
        FOREIGN KEY (product_id)
          REFERENCES products (id)
      )
    ''');
  }

  Future<void> _createStockMovementsTable(Database db) async {
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        product_id TEXT NOT NULL,
        movement_type TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        reference_id TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (product_id)
          REFERENCES products (id)
      )
    ''');
  }

  Future<void> _insertInitialProducts(Database db) async {
    final countResult = await db.rawQuery(
      'SELECT COUNT(*) AS count FROM products',
    );

    final count = countResult.first['count'] as int? ?? 0;

    if (count > 0) {
      return;
    }

    final products = [
      {
        'id': 'p-001',
        'short_code': 'COF001',
        'barcode': '890000000001',
        'name': 'Coffee',
        'category': 'Beverages',
        'price_cents': 299,
        'tax_rate': 19,
        'stock_quantity': 50,
        'is_active': 1,
      },
      {
        'id': 'p-002',
        'short_code': 'TEA001',
        'barcode': '890000000002',
        'name': 'Tea',
        'category': 'Beverages',
        'price_cents': 199,
        'tax_rate': 19,
        'stock_quantity': 40,
        'is_active': 1,
      },
      {
        'id': 'p-003',
        'short_code': 'SAN001',
        'barcode': '890000000003',
        'name': 'Sandwich',
        'category': 'Food',
        'price_cents': 499,
        'tax_rate': 7,
        'stock_quantity': 20,
        'is_active': 1,
      },
      {
        'id': 'p-004',
        'short_code': 'WAT001',
        'barcode': '890000000004',
        'name': 'Water',
        'category': 'Beverages',
        'price_cents': 149,
        'tax_rate': 19,
        'stock_quantity': 100,
        'is_active': 1,
      },
    ];

    await db.transaction((transaction) async {
      for (final product in products) {
        await transaction.insert(
          'products',
          product,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<void> _ensureReferenceData(Database db) async {
    await _insertInitialProducts(db);
  }

  Future<void> close() async {
    final database = _database;

    if (database != null && database.isOpen) {
      await database.close();
    }

    _database = null;
  }

  Future<void> deleteDatabaseForDevelopment() async {
    final databaseDirectory = await getDatabasesPath();

    final databasePath = join(databaseDirectory, _databaseName);

    await close();
    await deleteDatabase(databasePath);
  }
}
