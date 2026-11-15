import 'package:sqflite/sqflite.dart';

/// Schema version produced by [createBaselineSchema].
const int baselineSchemaVersion = 2;

/// One schema step. `appMigrations[n]` upgrades a database from n-1 to n.
typedef Migration = Future<void> Function(DatabaseExecutor db);

/// Ordered migrations. To change the schema, add the next version here; the
/// database version follows automatically ([latestSchemaVersion]).
final Map<int, Migration> appMigrations = {
  2: _v2CategoryAndOptionalBarcode,
  3: _v3StockMovementsAndSettings,
};

int get latestSchemaVersion =>
    appMigrations.keys.fold(baselineSchemaVersion, (a, b) => a > b ? a : b);

/// Applies migrations in (from, to] order.
Future<void> runMigrations(
  DatabaseExecutor db, {
  required int from,
  required int to,
}) async {
  final versions = appMigrations.keys.where((v) => v > from && v <= to).toList()
    ..sort();
  for (final version in versions) {
    await appMigrations[version]!(db);
  }
}

/// Schema as of [baselineSchemaVersion]; used for fresh installs only.
Future<void> createBaselineSchema(DatabaseExecutor db) async {
  await _createProductsTable(db, 'products');
  await db.execute('''
    CREATE UNIQUE INDEX idx_products_barcode_unique
    ON products (barcode)
    WHERE barcode IS NOT NULL AND barcode != ''
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
      FOREIGN KEY (sale_id)
        REFERENCES sales (id)
        ON DELETE CASCADE,
      FOREIGN KEY (product_id)
        REFERENCES products (id)
    )
  ''');
}

Future<void> _createProductsTable(DatabaseExecutor db, String name) {
  return db.execute('''
    CREATE TABLE $name (
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
}

Future<bool> hasColumn(DatabaseExecutor db, String table, String column) async {
  final columns = await db.rawQuery('PRAGMA table_info($table)');
  return columns.any((c) => c['name'] == column);
}

Future<void> addColumnIfMissing(
  DatabaseExecutor db,
  String table,
  String column,
  String definition,
) async {
  if (!await hasColumn(db, table, column)) {
    await db.execute('ALTER TABLE $table ADD COLUMN $column $definition');
  }
}

// v1 -> v2: product category, barcode made optional.
Future<void> _v2CategoryAndOptionalBarcode(DatabaseExecutor db) async {
  await addColumnIfMissing(
    db,
    'products',
    'category',
    "TEXT NOT NULL DEFAULT 'Other'",
  );

  await db.execute('PRAGMA defer_foreign_keys = ON');
  await _createProductsTable(db, 'products_new');
  await db.execute('''
    INSERT INTO products_new (
      id, short_code, barcode, name, category, image_path,
      price_cents, tax_rate, stock_quantity, is_active
    )
    SELECT
      id, short_code, barcode, name, category, image_path,
      price_cents, tax_rate, stock_quantity, is_active
    FROM products
  ''');
  await db.execute('DROP TABLE products');
  await db.execute('ALTER TABLE products_new RENAME TO products');
  await db.execute('''
    CREATE UNIQUE INDEX IF NOT EXISTS idx_products_barcode_unique
    ON products (barcode)
    WHERE barcode IS NOT NULL AND barcode != ''
  ''');
  await db.execute('PRAGMA defer_foreign_keys = OFF');
}

// v2 -> v3: stock movement ledger (previously only created on fresh installs,
// so some v2 databases lack it) and the runtime settings store.
Future<void> _v3StockMovementsAndSettings(DatabaseExecutor db) async {
  await db.execute('''
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
  await db.execute('''
    CREATE TABLE IF NOT EXISTS app_settings (
      key TEXT PRIMARY KEY,
      value TEXT NOT NULL
    )
  ''');
  await db.execute('''
    CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales (created_at)
  ''');
}
