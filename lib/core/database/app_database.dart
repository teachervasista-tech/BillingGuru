import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._internal();

  static final AppDatabase instance = AppDatabase._internal();

  static const String _databaseName = 'pos_billing.db';
  static const int _databaseVersion = 2;

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null && existingDatabase.isOpen) {
      //debugPrint('[Reports] Existing  database');
      return existingDatabase;
    }
    //debugPrint('[Reports] Opening database');
    _database = await _openDatabase();

    //debugPrint('[Reports] Database opened');
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
        final columns = await transaction.rawQuery(
          'PRAGMA table_info(products)',
        );
        final hasCategory = columns.any(
          (column) => column['name'] == 'category',
        );

        if (!hasCategory) {
          await transaction.execute('''
            ALTER TABLE products
            ADD COLUMN category TEXT NOT NULL DEFAULT 'Other'
          ''');
        }

        await transaction.execute('PRAGMA defer_foreign_keys = ON');
        await _makeBarcodeOptional(transaction);
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
      barcode TEXT,
      name TEXT NOT NULL,
      category TEXT NOT NULL DEFAULT 'Other',
      image_path TEXT,
      price_cents INTEGER NOT NULL,
      tax_rate INTEGER NOT NULL,
      stock_quantity INTEGER NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1
    )
  ''');

    await db.execute('''
      CREATE UNIQUE INDEX idx_products_barcode_unique
      ON products (barcode)
      WHERE barcode IS NOT NULL AND barcode != ''
    ''');
  }

  Future<void> _makeBarcodeOptional(Transaction transaction) async {
    await transaction.execute('''
      CREATE TABLE products_new (
        id TEXT PRIMARY KEY,
        short_code TEXT NOT NULL UNIQUE,
        barcode TEXT,
        name TEXT NOT NULL,
        category TEXT NOT NULL DEFAULT 'Other',
        image_path TEXT,
        price_cents INTEGER NOT NULL,
        tax_rate INTEGER NOT NULL,
        stock_quantity INTEGER NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await transaction.execute('''
      INSERT INTO products_new (
        id, short_code, barcode, name, category, image_path,
        price_cents, tax_rate, stock_quantity, is_active
      )
      SELECT
        id, short_code, barcode, name, category, image_path,
        price_cents, tax_rate, stock_quantity, is_active
      FROM products
    ''');

    await transaction.execute('DROP TABLE products');
    await transaction.execute('ALTER TABLE products_new RENAME TO products');
    await transaction.execute('''
      CREATE UNIQUE INDEX idx_products_barcode_unique
      ON products (barcode)
      WHERE barcode IS NOT NULL AND barcode != ''
    ''');
    await transaction.execute('PRAGMA defer_foreign_keys = OFF');
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
