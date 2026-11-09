# BillingGuru Database Schema

Complete documentation of the database structure and relationships.

## Database Overview

BillingGuru uses SQLite for local data persistence with automatic schema initialization and migration support.

**Database File Location**:
- Windows: `%APPDATA%/billing_guru/billing_guru.db`
- macOS: `~/Library/Application Support/billing_guru/billing_guru.db`
- iOS: `Documents/billing_guru.db`
- Android: `/data/data/com.billing_guru/databases/billing_guru.db`

## Database Tables

### 1. Products Table

Stores product/item information.

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  sku TEXT UNIQUE NOT NULL,
  category_id TEXT NOT NULL,
  unit_price REAL NOT NULL,
  cost_price REAL,
  current_stock INTEGER DEFAULT 0,
  min_stock INTEGER DEFAULT 5,
  description TEXT,
  status TEXT DEFAULT 'active',
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id)
)
```

**Columns**:
- `id` - Unique product identifier (UUID)
- `name` - Product name
- `sku` - Stock Keeping Unit (barcode)
- `category_id` - Associated category
- `unit_price` - Selling price
- `cost_price` - Purchase cost
- `current_stock` - Available quantity
- `min_stock` - Low stock threshold
- `description` - Product details
- `status` - active/inactive/discontinued
- `is_active` - Boolean for quick filtering
- `created_at` - Creation timestamp
- `updated_at` - Last modification timestamp

**Indexes**:
```sql
CREATE INDEX idx_products_sku ON products(sku);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_status ON products(status);
```

### 2. Categories Table

Product categories for organization.

```sql
CREATE TABLE categories (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  description TEXT,
  tax_rate REAL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Columns**:
- `id` - Unique category identifier
- `name` - Category name
- `description` - Category description
- `tax_rate` - Optional category-specific tax rate
- `created_at` - Creation timestamp
- `updated_at` - Last modification timestamp

### 3. Sales Table

Completed sales transactions.

```sql
CREATE TABLE sales (
  id TEXT PRIMARY KEY,
  order_number TEXT UNIQUE NOT NULL,
  customer_name TEXT,
  transaction_date TEXT NOT NULL,
  subtotal REAL NOT NULL,
  tax_amount REAL NOT NULL,
  discount_amount REAL DEFAULT 0,
  total_amount REAL NOT NULL,
  payment_method TEXT NOT NULL,
  payment_status TEXT DEFAULT 'completed',
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Columns**:
- `id` - Unique sale identifier
- `order_number` - Order/receipt number
- `customer_name` - Optional customer name
- `transaction_date` - Date of transaction
- `subtotal` - Sum before tax/discount
- `tax_amount` - Tax calculated
- `discount_amount` - Total discount applied
- `total_amount` - Final amount
- `payment_method` - How payment was made
- `payment_status` - completed/pending/cancelled
- `notes` - Additional transaction notes
- `created_at` - Record creation time
- `updated_at` - Last update time

**Indexes**:
```sql
CREATE INDEX idx_sales_date ON sales(transaction_date);
CREATE INDEX idx_sales_payment_method ON sales(payment_method);
CREATE INDEX idx_sales_status ON sales(payment_status);
```

### 4. Sale Items Table

Individual items in a sale transaction.

```sql
CREATE TABLE sale_items (
  id TEXT PRIMARY KEY,
  sale_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  product_name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  unit_price REAL NOT NULL,
  line_total REAL NOT NULL,
  discount REAL DEFAULT 0,
  tax_amount REAL DEFAULT 0,
  created_at TEXT NOT NULL,
  FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE,
  FOREIGN KEY (product_id) REFERENCES products(id)
)
```

**Columns**:
- `id` - Unique item identifier
- `sale_id` - Associated sale transaction
- `product_id` - Reference to product
- `product_name` - Product name (snapshot)
- `quantity` - Quantity sold
- `unit_price` - Price at time of sale
- `line_total` - quantity × unit_price
- `discount` - Item discount
- `tax_amount` - Tax on this item
- `created_at` - Record creation time

**Indexes**:
```sql
CREATE INDEX idx_sale_items_sale ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);
```

### 5. Stock Adjustments Table

History of inventory adjustments.

```sql
CREATE TABLE stock_adjustments (
  id TEXT PRIMARY KEY,
  product_id TEXT NOT NULL,
  adjustment_type TEXT NOT NULL,
  quantity_change INTEGER NOT NULL,
  reason TEXT,
  notes TEXT,
  previous_stock INTEGER NOT NULL,
  new_stock INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (product_id) REFERENCES products(id)
)
```

**Columns**:
- `id` - Unique adjustment identifier
- `product_id` - Product being adjusted
- `adjustment_type` - receipt/damage/return/correction/manual
- `quantity_change` - Positive or negative change
- `reason` - Adjustment reason
- `notes` - Additional details
- `previous_stock` - Stock before adjustment
- `new_stock` - Stock after adjustment
- `created_at` - When adjustment was made

**Indexes**:
```sql
CREATE INDEX idx_adjustments_product ON stock_adjustments(product_id);
CREATE INDEX idx_adjustments_date ON stock_adjustments(created_at);
```

### 6. Payment Methods Table

Supported payment types.

```sql
CREATE TABLE payment_methods (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL UNIQUE,
  code TEXT UNIQUE NOT NULL,
  is_active INTEGER DEFAULT 1,
  accept_partial_payment INTEGER DEFAULT 0,
  requires_reference INTEGER DEFAULT 0,
  description TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Columns**:
- `id` - Unique payment method identifier
- `name` - Display name (e.g., "Credit Card")
- `code` - System code (e.g., "CARD")
- `is_active` - Whether method is available
- `accept_partial_payment` - Allow partial payments
- `requires_reference` - Require reference number
- `description` - Payment method details
- `created_at` - Creation time
- `updated_at` - Last update time

**Default Payment Methods**:
- Cash (CASH)
- Card (CARD)
- UPI/Mobile (UPI)
- Cheque (CHEQUE)

### 7. Tax Rates Table

Tax configuration.

```sql
CREATE TABLE tax_rates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  rate REAL NOT NULL,
  category_id TEXT,
  is_default INTEGER DEFAULT 0,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories(id)
)
```

**Columns**:
- `id` - Unique tax rate identifier
- `name` - Tax name (GST, VAT, etc.)
- `rate` - Tax rate percentage
- `category_id` - Optional category-specific rate
- `is_default` - Default rate to use
- `is_active` - Whether rate is active
- `created_at` - Creation time
- `updated_at` - Last update time

### 8. Settings Table

Application configuration and preferences.

```sql
CREATE TABLE settings (
  id TEXT PRIMARY KEY,
  key TEXT NOT NULL UNIQUE,
  value TEXT NOT NULL,
  data_type TEXT NOT NULL,
  category TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Columns**:
- `id` - Unique setting identifier
- `key` - Setting key (e.g., "business_name")
- `value` - Setting value
- `data_type` - Type (string, number, boolean, json)
- `category` - Setting category
- `created_at` - Creation time
- `updated_at` - Last update time

**Common Settings**:
- `business_name` - Company name
- `business_address` - Address
- `business_phone` - Phone number
- `business_email` - Email
- `tax_id` - Tax registration
- `currency` - Currency code
- `default_tax_rate` - Default tax percentage
- `theme` - UI theme preference
- `language` - App language

### 9. Receipt Template Table

Custom receipt formatting.

```sql
CREATE TABLE receipt_templates (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  header_text TEXT,
  footer_text TEXT,
  show_logo INTEGER DEFAULT 1,
  show_business_details INTEGER DEFAULT 1,
  show_tax_id INTEGER DEFAULT 1,
  paper_width TEXT DEFAULT '80mm',
  font_size INTEGER DEFAULT 10,
  is_default INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
```

**Columns**:
- `id` - Unique template identifier
- `name` - Template name
- `header_text` - Receipt header message
- `footer_text` - Receipt footer message
- `show_logo` - Display logo
- `show_business_details` - Show contact info
- `show_tax_id` - Show tax ID
- `paper_width` - Receipt width (58mm, 80mm)
- `font_size` - Text size
- `is_default` - Default template
- `created_at` - Creation time
- `updated_at` - Last update time

### 10. Audit Log Table (Optional)

Track important changes for audit trail.

```sql
CREATE TABLE audit_logs (
  id TEXT PRIMARY KEY,
  entity_type TEXT NOT NULL,
  entity_id TEXT NOT NULL,
  action TEXT NOT NULL,
  old_value TEXT,
  new_value TEXT,
  user_id TEXT,
  created_at TEXT NOT NULL
)
```

**Columns**:
- `id` - Log entry identifier
- `entity_type` - Type of entity changed (product, sale, etc.)
- `entity_id` - ID of changed entity
- `action` - Action performed (create/update/delete)
- `old_value` - Previous value (JSON)
- `new_value` - New value (JSON)
- `user_id` - User performing action
- `created_at` - When change occurred

## Database Relationships

```
┌──────────────┐
│  Categories  │
└──────┬───────┘
       │
       │ 1:N
       ↓
┌──────────────────┐
│    Products      │
└────────┬─────────┘
         │
         │ 1:N
         ↓
    ┌─────────────────┐
    │   Sale Items    │
    └────────┬────────┘
             │
             │ N:1
             ↓
        ┌─────────┐
        │  Sales  │
        └────┬────┘
             │
             │ N:1
             ↓
    ┌─────────────────────┐
    │  Payment Methods    │
    └─────────────────────┘

    Stock Adjustments → Products (N:1)
    Tax Rates → Categories (N:1, optional)
    Settings (key-value store)
    Receipt Templates (configuration)
```

## Data Types

- **TEXT**: Strings, dates (ISO 8601 format)
- **REAL**: Decimal numbers (prices, tax rates)
- **INTEGER**: Whole numbers (quantities, flags)
- **BLOB**: Binary data (future for images)

## Constraints

**Primary Keys**: All tables use TEXT primary keys (UUIDs)

**Foreign Keys**: Enabled to maintain referential integrity

**Unique Constraints**:
- products.sku
- categories.name
- sales.order_number
- payment_methods.name
- payment_methods.code
- settings.key
- tax_rates.name

**NOT NULL Constraints**: Applied to essential fields

**Default Values**:
- `is_active`: 1 (true)
- `status`: 'active'
- `quantity`: 0

## Indexes

Strategic indexes for common queries:

```
products: sku, category_id, status
sales: transaction_date, payment_method, payment_status
sale_items: sale_id, product_id
stock_adjustments: product_id, created_at
```

## Database Operations

### Initialize Database

```dart
final db = await AppDatabase.instance.database;
```

### Insert Record

```dart
final id = await db.insert('products', productMap);
```

### Query Records

```dart
final products = await db.query(
  'products',
  where: 'category_id = ?',
  whereArgs: [categoryId],
);
```

### Update Record

```dart
await db.update(
  'products',
  productMap,
  where: 'id = ?',
  whereArgs: [productId],
);
```

### Delete Record

```dart
await db.delete(
  'products',
  where: 'id = ?',
  whereArgs: [productId],
);
```

### Transaction

```dart
await db.transaction((txn) async {
  // Multiple operations in transaction
  await txn.insert('products', product);
  await txn.insert('sales', sale);
});
```

## Backup & Recovery

**Backup Location**: 
User's Documents or cloud storage (configurable)

**Backup Contents**:
- Complete SQLite database file
- All tables and data
- Indexes and constraints

**Recovery Process**:
1. Delete current database file
2. Restore backup file
3. Reinitialize database
4. Reload data

## Performance Optimization

### Query Optimization
- Use indexes on frequently queried columns
- Limit result sets with WHERE clauses
- Use LIMIT for pagination

### Database Maintenance
- VACUUM to optimize file size
- ANALYZE to update statistics
- Regular backups to prevent data loss

### Batch Operations
```dart
await db.transaction((txn) async {
  for (var item in items) {
    await txn.insert('sale_items', item);
  }
});
```

## Migration Strategy

Database versions managed in initialization:

```dart
onUpgrade: (db, oldVersion, newVersion) {
  // Run migrations based on version
  if (oldVersion < 2) {
    // Migration from v1 to v2
  }
}
```

---

For data access patterns, see [API Reference](./07-api-reference.md) or [Architecture](./05-architecture.md).
