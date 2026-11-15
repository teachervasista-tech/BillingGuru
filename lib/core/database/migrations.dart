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
  4: _v4Expenses,
};

/// Built-in expense categories (id, name, ARGB color). `cat-stock` is used
/// when receiving stock with a cost.
const defaultExpenseCategories = [
  ('cat-rent', 'Rent', 0xFF5C6BC0),
  ('cat-utilities', 'Utilities', 0xFF26A69A),
  ('cat-salaries', 'Salaries', 0xFFEF6C00),
  ('cat-stock', 'Stock purchase', 0xFF8D6E63),
  ('cat-transport', 'Transport', 0xFF29B6F6),
  ('cat-maintenance', 'Maintenance', 0xFF78909C),
  ('cat-marketing', 'Marketing', 0xFFEC407A),
  ('cat-other', 'Other', 0xFF9E9E9E),
];
const stockPurchaseCategoryId = 'cat-stock';

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

// v3 -> v4: expenditure management and cost tracking.
Future<void> _v4Expenses(DatabaseExecutor db) async {
  await addColumnIfMissing(
    db,
    'products',
    'cost_price_cents',
    'INTEGER NOT NULL DEFAULT 0',
  );
  await addColumnIfMissing(
    db,
    'sale_items',
    'unit_cost_cents',
    'INTEGER NOT NULL DEFAULT 0',
  );
  await addColumnIfMissing(db, 'stock_movements', 'unit_cost_cents', 'INTEGER');
  await addColumnIfMissing(db, 'stock_movements', 'supplier', 'TEXT');
  await addColumnIfMissing(db, 'stock_movements', 'expense_id', 'TEXT');

  await db.execute('''
    CREATE TABLE IF NOT EXISTS expense_categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL COLLATE NOCASE UNIQUE,
      color INTEGER NOT NULL,
      monthly_budget_cents INTEGER NOT NULL DEFAULT 0,
      is_active INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS recurring_expenses (
      id TEXT PRIMARY KEY,
      category_id TEXT NOT NULL,
      amount_cents INTEGER NOT NULL,
      payment_method TEXT NOT NULL,
      vendor TEXT,
      note TEXT,
      frequency TEXT NOT NULL,
      next_due_date TEXT NOT NULL,
      is_active INTEGER NOT NULL DEFAULT 1,
      created_at TEXT NOT NULL,
      FOREIGN KEY (category_id) REFERENCES expense_categories (id)
    )
  ''');
  await db.execute('''
    CREATE TABLE IF NOT EXISTS expenses (
      id TEXT PRIMARY KEY,
      category_id TEXT NOT NULL,
      amount_cents INTEGER NOT NULL,
      tax_cents INTEGER NOT NULL DEFAULT 0,
      payment_method TEXT NOT NULL,
      vendor TEXT,
      reference_no TEXT,
      note TEXT,
      attachment_path TEXT,
      expense_date TEXT NOT NULL,
      created_at TEXT NOT NULL,
      recurring_id TEXT,
      FOREIGN KEY (category_id) REFERENCES expense_categories (id),
      FOREIGN KEY (recurring_id) REFERENCES recurring_expenses (id)
        ON DELETE SET NULL
    )
  ''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses (expense_date)',
  );

  for (final (index, (id, name, color)) in defaultExpenseCategories.indexed) {
    await db.insert('expense_categories', {
      'id': id,
      'name': name,
      'color': color,
      'sort_order': index,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
