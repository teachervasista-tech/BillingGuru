# Billing Guru 2.0.0 — Release Notes

Release date: 2026-11-15 · Package: `BillingGuru-2.0.0-windows-x64-2026-11-15.zip`

## Before you upgrade

- **Make a copy of your data folder first.** 2.0.0 upgrades the database
  (schema v2 → v7) the first time it starts. The upgrade keeps all products
  and sales, but version 1.0.0 cannot open the upgraded database afterwards.
- After upgrading, use **Settings → Data → Create backup** regularly.

## What's new

### Users: Installer, Admin and Seller

- **First start:** sign in as **`installer`** with password **`installer`**
  (the login screen shows this hint until it is changed). The installer must
  choose a new password before continuing. Keep it safe — there is no recovery.
- The installer sets the shop up (Business, Tax, Printer, receipt logo,
  Payment options, Modules, Data) and creates the **Admin** and **Seller**
  accounts in **Settings → Users**. The installer account cannot be disabled
  or changed by others and is not shown in admins' user list.
- Everyone signs in with username and password. The account button at the
  bottom of the navigation menu shows who is signed in and offers **Change
  password** and **Sign out**.
- Admins can also add sellers or admins, reset passwords, switch roles and
  disable accounts. The last active admin can't be disabled or demoted.

| | Installer | Admin | Seller |
|---|:-:|:-:|:-:|
| Settings → Business, Printer (incl. logo), Payment options, Modules, Data | ✓ | | |
| Settings → Tax | ✓ | ✓ | |
| Settings → Users | ✓ | ✓ | |
| Settings → Product categories, Expense categories | | ✓ | |
| PoS, checkout, receipts, sales history | | ✓ | ✓ |
| View products and stock, customers, dashboard sales charts | | ✓ | ✓ |
| Add/edit products, adjust stock | | ✓ | |
| Void sales, return items | | ✓ | |
| Expenses, reports, profit & loss | | ✓ | |

- The installer goes straight to Settings; sellers have no Settings at all.
- Each sale records who made it ("Sold by" in the sale details).
- Restoring a backup signs everyone out, since accounts come from the backup.

### Receipt logo

- **Settings → Printer → Receipt logo** (installer): upload a picture and
  choose *Default*, *Uploaded* or *No logo*.
- Uploads are converted for receipt printers: transparency becomes white,
  empty borders are trimmed, contrast is boosted and the image is sized to at
  most 384 × 160 dots — the native resolution of 58 mm and 80 mm thermal
  printers.
- Print style: **Black & white** (sharpest, for logos and text),
  **Dithered** (photos or shaded logos) or **Grayscale** (laser/inkjet). The
  original is kept, so the style can be changed later without re-uploading.
  The logo is included in backups.

### Expenses (new module)

- Record shop expenses with date, category, amount (tax included), tax portion,
  how it was paid, vendor, bill number, note and a scanned receipt (image or PDF).
- Filter by period, category or text; export the list to CSV for your accountant.
- **Monthly budgets** per category (Settings → Expense categories). Spending is
  shown against the budget, scaled to the selected period; over-budget
  categories are highlighted.
- **Recurring expenses** (rent, salaries, subscriptions): choose *Repeat* when
  adding an expense. Each due occurrence is added automatically when the
  Expenses screen opens; manage them with the ⟳ button.

### Profit & loss

- Products have an optional **cost price** (product form or the *Cost price*
  column in Excel import). The cost is saved with every sale.
- **Inventory → Adjust stock → Add** can record the unit cost and supplier. The
  product cost becomes the weighted average of old and new stock, and the
  purchase can be recorded as a *Stock purchase* expense in the same step.
- The Dashboard and Reports show a **Profit & loss** card:
  net sales − cost of goods sold = gross profit; − operating expenses = net
  profit. Stock purchases are shown separately as cash out (they reach profit
  through cost of goods sold when the items sell, so they are not counted twice).
  Export to CSV with the download button.
- New report periods: *Last month* and *Financial year*.

### Product categories

- **Settings → Product categories** (admin): add, rename, recolor, reorder,
  archive and delete categories — like expense categories.
- Existing categories are created automatically from your products on upgrade.
- Renaming updates every product in the category. Deleting asks where to move
  its products. Archived categories aren't offered in the product form.
- The category list on the PoS and Products screens follows your order and
  shows each category's color.
- Typing a new category in the product form (or importing one from Excel)
  still works — it is added to the list automatically.

### Customers (replaces the placeholder screen)

- Customer list with search, details, lifetime value, average sale and purchase
  history.
- On the PoS, attach a customer to the sale (or quick-add one). The name is
  printed on the receipt.

### Returns and voids

- In Sales history → view a sale: **Return items** (choose quantities) or
  **Void sale**. Stock goes back automatically, the refund includes the
  proportional tax, and reports, profit and customer totals exclude the
  refunded amounts.

### Settings without rebuilding

Values that previously required editing `assets/config/*` and rebuilding the
app are now changed in the app:

| Tab | Who | Settings |
|---|---|---|
| Business | Installer | Receipt header (business name, address, tax ID), currency, financial-year start, invoice numbering (daily / monthly / yearly), low-stock threshold, color theme |
| Tax | Installer, Admin | Default tax rate |
| Printer | Installer | Receipt layout, paper size, receipt logo |
| Payment options | Installer | Payment buttons at checkout |
| Modules | Installer | Show or hide Home, PoS, Products, Customers, Sales, Expenses, Reports, Inventory; turn the payment screen on or off |
| Data | Installer | Backup, restore, app version, database location |
| Users | Installer, Admin | Admin and Seller accounts |
| Product categories | Admin | Names, colors, order, archive, delete (moving products) |
| Expense categories | Admin | Names, colors, monthly budgets, archive |

The files in `assets/config/` are still used as **first-run defaults**.

### Backup and restore

**Settings → Data → Create backup** writes one `.zip` containing the database,
product images, expense receipts and printer/tax/payment preferences. **Restore
from backup** replaces all current data (after confirmation) and works on a
different computer — file paths are re-linked automatically.

### Other improvements

- Low-stock badges in Inventory now follow the configured threshold (was
  always 10).
- A database created by early builds could be missing the stock movement table;
  the upgrade now adds it.
- Reprinting a receipt from Sales history no longer relies on a provider read
  inside a button callback (could print stale items).

## Module defaults

`assets/config/features.json` in this build keeps the shop's current choices:
Customers, Reports and the payment screen are **off** by default. Turn them on
in **Settings → Modules**; Expenses is on.

## For developers

### Structure

- `lib/app/modules.dart` — one `AppModule` entry per area; the router, route
  guard and navigation rail are generated from it. To add a module, add an entry
  (and a key in `AppFeatures` if it can be switched off).
- `lib/core/settings/` — `AppSettings` (immutable), `AppSettingsNotifier`,
  DB-backed `SettingsStore` (table `app_settings`); `InMemorySettingsStore` for
  tests.
- `lib/core/database/` — `appDatabaseProvider` (override in tests),
  `migrations.dart` (ordered map; add the next version to change the schema),
  `RowReader` extension for typed row access.
- `lib/features/auth/` — `UserService`, `PasswordHasher`, `authProvider`
  (setup / signed out / signed in), `canProvider(Permission)`. Roles map to
  `Permission`s in `UserRole`; modules declare a required `permission` in
  `AppModule`.
- `lib/core/period/date_range.dart` — `DateRange` and `PeriodPreset`, shared by
  sales, reports and expenses (`SalesPeriod`/`SalesDateRange` remain as aliases).
- Shared helpers: `MoneyInput`, `CsvExport`, `AppFileStorage`,
  `PeriodDropdown`, `SectionCard`, `openWithSystem`, `refreshAllData`.

### Schema v7 (new and changed)

| Table / view | Purpose |
|---|---|
| `app_settings(key, value)` | Runtime settings |
| `expense_categories` | Seeded categories (`cat-stock` = stock purchases), `monthly_budget_cents` |
| `expenses` | `amount_cents`, `tax_cents`, `payment_method`, `expense_date`, `attachment_path`, `recurring_id` |
| `recurring_expenses` | Templates with `frequency` and `next_due_date` |
| `customers` | Contact details |
| `product_categories` | Managed product categories (`name` unique, case-insensitive; `color`, `sort_order`, `is_active`). Products keep the category name |
| `users` | Accounts: `username` (unique, case-insensitive), `role` (`installer`/`admin`/`seller`), `password_hash` (PBKDF2-HMAC-SHA256, salted), `is_active`, `must_change_password`. The installer row is created in v7 |
| `sales.user_id` | Who made the sale |
| `sale_returns`, `sale_return_items` | Void/return audit trail |
| `products.cost_price_cents` | Current (average) cost |
| `sale_items.unit_cost_cents`, `returned_quantity` | Cost snapshot, returns |
| `sales.customer_id`, `status`, `refunded_cents`, `refunded_tax_cents` | Customer link, lifecycle |
| `stock_movements.unit_cost_cents`, `supplier`, `expense_id` | Purchase costing |
| view `effective_sales`, `effective_sale_items` | Sales net of voids/returns — **use these in reports** |

### Testing

`test/helpers/test_container.dart` provides `createTestDatabase()` (in-memory
SQLite via FFI) and `createTestContainer()` (in-memory settings, optional DB
override). 82 tests cover migrations (fresh vs. upgraded schema equality),
settings, modules, expenses, recurring, P&L, returns, customers, backup,
users/permissions, receipt logo conversion and the installer → admin →
seller sign-in flow. Pass `user: testAdmin` /
`testSeller` to `createTestContainer` for screens that check permissions.
