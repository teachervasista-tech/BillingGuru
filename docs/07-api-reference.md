# BillingGuru API Reference

Core modules, providers, and services documentation.

## Core Providers

### Currency Provider

Manages currency configuration and formatting.

**Location**: `lib/core/currency/currency_provider.dart`

```dart
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>(...);
```

**Methods**:
- `loadCurrencyFromAsset()` - Load from configuration file
- `setCurrency(Currency currency)` - Update currency

**Usage**:
```dart
final currency = ref.watch(currencyProvider);
final notifier = ref.read(currencyProvider.notifier);

// Format amount
String formatted = currency.format(1000.50); // ₹ 1,000.50
```

**Currency Model**:
```dart
class Currency {
  final String code;          // ISO code (INR, USD, etc.)
  final String symbol;        // Display symbol (₹, $, €)
  final String name;          // Full name
  final String decimalSeparator;
  final String thousandSeparator;
  final int decimalPlaces;
  final CurrencyPosition position;
  final bool spaceBetween;
}
```

### Tax Rate Provider

Manages tax configuration.

**Location**: `lib/core/tax/tax_rate_provider.dart`

```dart
final defaultTaxRateProvider = StateNotifierProvider<TaxRateNotifier, double>(...);
```

**Methods**:
- `loadSavedTaxRate()` - Load saved tax rate
- `setTaxRate(double rate)` - Update tax rate
- `calculateTax(double amount, double rate)` - Calculate tax

**Usage**:
```dart
final taxRate = ref.watch(defaultTaxRateProvider);
final tax = _calculateTax(1000, taxRate); // Tax on ₹1000
```

### Receipt Template Provider

Manages receipt formatting.

**Location**: `lib/core/printing/receipt_template_provider.dart`

```dart
final receiptTemplateProvider = StateNotifierProvider<ReceiptTemplateNotifier, ReceiptTemplate>(...);
```

**Methods**:
- `loadSavedTemplate()` - Load saved template
- `updateTemplate(ReceiptTemplate template)` - Save template

**ReceiptTemplate Model**:
```dart
class ReceiptTemplate {
  final String id;
  final String name;
  final String headerText;
  final String footerText;
  final bool showLogo;
  final bool showBusinessDetails;
  final bool showTaxId;
  final String paperWidth;  // '58mm' or '80mm'
  final int fontSize;
  final bool isDefault;
}
```

## Feature Services

### Cart Management

**Location**: `lib/features/cart/`

#### CartProvider (StateNotifier)

```dart
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(...);
```

**State**:
```dart
class CartState {
  final List<CartItem> items;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final bool isEmpty;
}
```

**Methods**:
```dart
// Add product to cart
await ref.read(cartProvider.notifier).addItem(Product product, {int quantity});

// Remove item
await ref.read(cartProvider.notifier).removeItem(String itemId);

// Update quantity
await ref.read(cartProvider.notifier).updateQuantity(String itemId, int quantity);

// Apply discount
await ref.read(cartProvider.notifier).applyDiscount(double amount);

// Clear cart
await ref.read(cartProvider.notifier).clearCart();

// Get cart total
double total = ref.watch(cartProvider).totalAmount;
```

**CartItem Model**:
```dart
class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final double lineTotal;
  final double discount;
  final double tax;
}
```

### Product Management

**Location**: `lib/features/products/` or `lib/features/inventory/`

#### ProductsProvider

```dart
final productsProvider = FutureProvider<List<Product>>(...);
final productByIdProvider = FutureProvider.family<Product, String>(...);
```

**Methods**:
```dart
// Get all products
final products = await ref.refresh(productsProvider);

// Get single product
final product = await ref.refresh(productByIdProvider(productId));

// Add product
await productRepository.addProduct(Product product);

// Update product
await productRepository.updateProduct(Product product);

// Delete product
await productRepository.deleteProduct(String productId);

// Search products
final results = await productRepository.searchProducts(String query);
```

**Product Model**:
```dart
class Product {
  final String id;
  final String name;
  final String sku;           // Barcode
  final String categoryId;
  final double unitPrice;
  final double costPrice;
  final int currentStock;
  final int minStock;
  final String description;
  final String status;        // active, inactive, discontinued
  final DateTime createdAt;
  final DateTime updatedAt;
}
```

### Sales Management

**Location**: `lib/features/sales/`

#### SalesProvider

```dart
final salesProvider = FutureProvider<List<Sale>>(...);
final saleByIdProvider = FutureProvider.family<Sale, String>(...);
final salesByDateProvider = FutureProvider.family<List<Sale>, DateRange>(...);
```

**Methods**:
```dart
// Get all sales
final sales = await ref.refresh(salesProvider);

// Get sales by date range
final sales = await ref.refresh(salesByDateProvider(dateRange));

// Get sale details
final sale = await ref.refresh(saleByIdProvider(saleId));

// Save sale
await saleRepository.saveSale(Sale sale);

// Get sale by order number
final sale = await saleRepository.getSaleByOrderNumber(String orderNumber);
```

**Sale Model**:
```dart
class Sale {
  final String id;
  final String orderNumber;
  final String? customerName;
  final DateTime transactionDate;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;      // completed, pending, cancelled
  final List<SaleItem> items;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class SaleItem {
  final String id;
  final String saleId;
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final double discount;
  final double taxAmount;
}
```

### Checkout & Payment

**Location**: `lib/features/checkout/`

#### CheckoutProvider

```dart
final checkoutProvider = StateNotifierProvider<CheckoutNotifier, CheckoutState>(...);
final paymentMethodsProvider = FutureProvider<List<PaymentMethod>>(...);
```

**CheckoutState**:
```dart
class CheckoutState {
  final double totalAmount;
  final String selectedPaymentMethod;
  final double amountReceived;
  final double changeAmount;
  final bool isProcessing;
  final String? error;
}
```

**Methods**:
```dart
// Select payment method
await ref.read(checkoutProvider.notifier).selectPaymentMethod(String methodId);

// Set amount received
await ref.read(checkoutProvider.notifier).setAmountReceived(double amount);

// Process payment
final result = await ref.read(checkoutProvider.notifier).processPayment();

// Get payment methods
final methods = await ref.refresh(paymentMethodsProvider);
```

**PaymentMethod Model**:
```dart
class PaymentMethod {
  final String id;
  final String name;
  final String code;
  final bool isActive;
  final bool acceptPartialPayment;
  final bool requiresReference;
  final String? description;
}
```

### Reports & Analytics

**Location**: `lib/features/reports/`

#### ReportProviders

```dart
final dailySalesReportProvider = FutureProvider<DailySalesReport>(...);
final categoryReportProvider = FutureProvider.family<CategoryReport, String>(...);
final taxReportProvider = FutureProvider.family<TaxReport, DateRange>(...);
final productPerformanceProvider = FutureProvider<List<ProductPerformance>>(...);
```

**Methods**:
```dart
// Generate daily sales report
final report = await ref.refresh(dailySalesReportProvider);

// Generate category report
final report = await ref.refresh(categoryReportProvider(categoryId));

// Generate tax report
final report = await ref.refresh(taxReportProvider(dateRange));

// Export report
String pdf = await reportService.exportToPDF(report);
String csv = await reportService.exportToCSV(report);
```

**Report Models**:
```dart
class DailySalesReport {
  final DateTime date;
  final int totalTransactions;
  final double totalRevenue;
  final double totalTax;
  final double totalDiscount;
  final Map<String, double> paymentMethodBreakdown;
  final List<TopProduct> topProducts;
}

class CategoryReport {
  final String categoryId;
  final String categoryName;
  final double totalSales;
  final int itemsSold;
  final double averagePrice;
  final double currentStock;
}

class TaxReport {
  final DateRange period;
  final double totalTaxCollected;
  final Map<String, double> taxByCategory;
  final Map<String, double> taxByPaymentMethod;
}

class ProductPerformance {
  final Product product;
  final int unitsSold;
  final double totalRevenue;
  final int currentStock;
  final String trend;              // up, down, stable
}
```

### Settings & Configuration

**Location**: `lib/features/settings/`

#### SettingsProvider

```dart
final appSettingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>(...);
final businessDetailsProvider = FutureProvider<BusinessDetails>(...);
```

**AppSettings Model**:
```dart
class AppSettings {
  final String theme;                    // light, dark, auto
  final String language;
  final bool enableNotifications;
  final int autoLogoutMinutes;
  final String? preferredPrinter;
}

class BusinessDetails {
  final String businessName;
  final String businessAddress;
  final String businessPhone;
  final String businessEmail;
  final String businessTaxId;
  final String? logoPath;
}
```

**Methods**:
```dart
// Get settings
final settings = ref.watch(appSettingsProvider);

// Update settings
await ref.read(appSettingsProvider.notifier).updateSettings(AppSettings settings);

// Get business details
final details = await ref.refresh(businessDetailsProvider);

// Update business details
await settingsRepository.updateBusinessDetails(BusinessDetails details);

// Save backup
String backupPath = await settingsRepository.createBackup();

// Restore backup
await settingsRepository.restoreBackup(String backupPath);
```

## Core Services

### Database Service

**Location**: `lib/core/database/app_database.dart`

```dart
final database = await AppDatabase.instance.database;
```

**Methods**:
```dart
// Execute query
List<Map<String, dynamic>> results = await db.query('products');

// Insert
int id = await db.insert('products', data);

// Update
int updated = await db.update('products', data, where: 'id = ?', whereArgs: [id]);

// Delete
int deleted = await db.delete('products', where: 'id = ?', whereArgs: [id]);

// Transaction
await db.transaction((txn) async {
  // Multiple operations
});

// Raw SQL
List<Map> results = await db.rawQuery('SELECT * FROM products WHERE price > ?', [100]);

// Close database
await db.close();
```

### Printing Service

**Location**: `lib/core/printing/`

```dart
final printingServiceProvider = Provider<PrintingService>(...);
```

**Methods**:
```dart
// Print receipt
await printingService.printReceipt(SaleReceipt receipt);

// Generate PDF
Uint8List pdf = await printingService.generateReceiptPDF(SaleReceipt receipt);

// Print from PDF
await printingService.printFromPDF(Uint8List pdf);

// Get available printers
List<Printer> printers = await printingService.getAvailablePrinters();

// Set default printer
await printingService.setDefaultPrinter(String printerName);

// Preview receipt
await printingService.previewReceipt(SaleReceipt receipt);
```

**SaleReceipt Model**:
```dart
class SaleReceipt {
  final Sale sale;
  final String orderNumber;
  final List<SaleItem> items;
  final String paymentMethod;
  final String currencySymbol;
  final ReceiptTemplate template;
}
```

### File Storage Service

**Location**: `lib/core/storage/`

```dart
final storageServiceProvider = Provider<StorageService>(...);
```

**Methods**:
```dart
// Save file
String path = await storageService.saveFile(String fileName, Uint8List data);

// Load file
Uint8List data = await storageService.loadFile(String fileName);

// Delete file
await storageService.deleteFile(String fileName);

// Get backup directory
String backupDir = await storageService.getBackupDirectory();

// List files
List<String> files = await storageService.listFiles(String directory);

// Export data
await storageService.exportToCSV(List<dynamic> data, String fileName);

// Clear app cache
await storageService.clearCache();
```

## Configuration Management

### AppFeatures

**Location**: `lib/core/config/app_features.dart`

```dart
static Future<void> load() async {
  // Load features.json
}

static bool isFeatureEnabled(String featureName) {
  // Check if feature is enabled
}
```

**Usage**:
```dart
if (AppFeatures.isFeatureEnabled('barcode_scanning')) {
  // Show barcode scanner
}
```

### AppColorTheme

**Location**: `lib/app/theme.dart`

```dart
static Future<void> load() async {
  // Load color themes
}

static ThemeData getCurrentTheme() {
  // Get current theme
}

static void setTheme(String themeId) {
  // Change theme
}
```

## Riverpod Best Practices

### Provider Definitions

```dart
// Simple provider
final simpleProvider = Provider((ref) => 'value');

// State provider
final stateProvider = StateProvider<String>((ref) => 'initial');

// StateNotifier provider
final notifierProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});

// FutureProvider for async data
final asyncProvider = FutureProvider<List<Product>>((ref) async {
  return await repository.fetchProducts();
});

// FamilyProvider for parameterized providers
final familyProvider = FutureProvider.family<Product, String>((ref, productId) async {
  return await repository.getProduct(productId);
});

// Select specific fields
final selectedField = ref.watch(
  productsProvider.select((products) => products.length)
);
```

### Provider Consumption

```dart
// Watch provider (rebuilds on change)
final value = ref.watch(myProvider);

// Read provider (one-time access)
final value = ref.read(myProvider);

// Watch with select (partial rebuild)
final length = ref.watch(myProvider.select((state) => state.length));

// Invalidate provider (refresh)
ref.invalidate(myProvider);

// Refresh provider (refetch)
final data = await ref.refresh(asyncProvider);

// Listen to changes
ref.listen(myProvider, (previous, next) {
  // React to changes
});
```

## Error Handling

### Exception Types

```dart
class RepositoryException implements Exception {
  final String message;
  final dynamic originalException;
  final StackTrace? stackTrace;
}

class DatabaseException extends RepositoryException {}
class NetworkException extends RepositoryException {}
class ValidationException extends RepositoryException {}
```

### Error Handling Pattern

```dart
try {
  final data = await repository.fetchData();
  return data;
} on RepositoryException catch (e) {
  logger.e('Repository error: ${e.message}');
  rethrow;
} catch (e, st) {
  logger.e('Unexpected error', error: e, stackTrace: st);
  throw RepositoryException('Unexpected error: $e');
}
```

---

For more details on specific features, see [Features](./03-features.md) or [Database Schema](./06-database-schema.md).
