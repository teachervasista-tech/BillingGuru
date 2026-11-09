# BillingGuru Configuration Guide

Complete guide to configuring BillingGuru for your specific needs.

## Configuration Files

Configuration files are stored in the `assets/config/` directory and loaded at application startup.

### 1. Feature Flags (features.json)

Controls which features are enabled in the application.

**Location**: `assets/config/features.json`

**Example Configuration**:
```json
{
  "billing": true,
  "inventory": true,
  "reports": true,
  "barcode_scanning": true,
  "receipt_printing": true,
  "sales_history": true,
  "dashboard": true,
  "tax_calculation": true,
  "multiple_payment_methods": true,
  "category_management": true,
  "discount_system": true,
  "reprint_receipts": true,
  "bulk_operations": false,
  "customer_database": false,
  "loyalty_program": false,
  "cloud_sync": false
}
```

**Feature Descriptions**:
- `billing` - Main POS billing functionality
- `inventory` - Product and stock management
- `reports` - Analytics and report generation
- `barcode_scanning` - Barcode scanner support
- `receipt_printing` - Receipt generation and printing
- `sales_history` - Transaction history tracking
- `dashboard` - Business dashboard with metrics
- `tax_calculation` - Tax calculation on sales
- `multiple_payment_methods` - Various payment options
- `category_management` - Product categorization
- `discount_system` - Item and transaction discounts
- `reprint_receipts` - Ability to reprint old receipts
- `bulk_operations` - Bulk product/stock operations
- `customer_database` - Customer management
- `loyalty_program` - Customer loyalty features
- `cloud_sync` - Cloud backup and synchronization

**Loading Features in Code**:
```dart
// Access feature flags
bool isBillingEnabled = AppFeatures.isFeatureEnabled('billing');
bool hasInventory = AppFeatures.isFeatureEnabled('inventory');
```

### 2. Color Themes (color_themes.json)

Define available UI color schemes.

**Location**: `assets/config/color_themes.json`

**Example Configuration**:
```json
{
  "themes": [
    {
      "id": "default",
      "name": "Default",
      "isDark": false,
      "colors": {
        "primary": "#2196F3",
        "secondary": "#FF9800",
        "background": "#FFFFFF",
        "surface": "#F5F5F5",
        "error": "#F44336",
        "success": "#4CAF50",
        "warning": "#FFC107"
      }
    },
    {
      "id": "dark",
      "name": "Dark",
      "isDark": true,
      "colors": {
        "primary": "#BB86FC",
        "secondary": "#03DAC6",
        "background": "#121212",
        "surface": "#1E1E1E",
        "error": "#CF6679",
        "success": "#81C784",
        "warning": "#FFB74D"
      }
    }
  ]
}
```

**Color Definitions**:
- `primary` - Main brand color (buttons, headers)
- `secondary` - Accent color
- `background` - App background
- `surface` - Card/dialog backgrounds
- `error` - Error state colors
- `success` - Success indicators
- `warning` - Warning/alert colors

### 3. Currency Configuration (currency.txt)

Define currency settings and formatting.

**Location**: `assets/config/currency.txt`

**Example Configuration**:
```
code=INR
symbol=₹
name=Indian Rupee
decimal_separator=.
thousand_separator=,
decimal_places=2
position=prefix
space_between=false
```

**Configuration Options**:
- `code` - ISO 4217 currency code (INR, USD, EUR, GBP, etc.)
- `symbol` - Currency symbol to display
- `name` - Full currency name
- `decimal_separator` - Decimal separator character (. or ,)
- `thousand_separator` - Thousands separator (, or .)
- `decimal_places` - Number of decimal places (typically 2)
- `position` - Symbol position (prefix or suffix)
- `space_between` - Add space between symbol and amount

**Common Currencies**:
```
USD: $, code=USD, decimal_places=2
EUR: €, code=EUR, decimal_places=2
GBP: £, code=GBP, decimal_places=2
INR: ₹, code=INR, decimal_places=2
JPY: ¥, code=JPY, decimal_places=0
```

### 4. Financial Year Start (financial_year_start.txt)

Configure financial year for reporting.

**Location**: `assets/config/financial_year_start.txt`

**Example Configuration**:
```
month=1
day=1
```

**Supported Start Dates**:
- January 1 (month=1, day=1) - Calendar year
- April 1 (month=4, day=1) - India fiscal year
- July 1 (month=7, day=1) - Australia/USA
- October 1 (month=10, day=1) - Some countries

**Usage**: Reports and analytics will be grouped by financial years starting on this date.

### 5. Invoice/Order Sequence (invoice_sequence.txt)

Configure invoice numbering format.

**Location**: `assets/config/invoice_sequence.txt`

**Example Configuration**:
```
prefix=INV
start_number=1000
increment=1
separator=-
date_format=YYYYMMDD
```

**Configuration Options**:
- `prefix` - Prefix for invoice numbers (e.g., INV, BL, ORD)
- `start_number` - Starting invoice number
- `increment` - How much to increment each invoice
- `separator` - Separator character(s)
- `date_format` - Optional date format (YYYYMMDD, MMDD, YY, etc.)

**Example Outputs**:
- With date: `INV-20261109-1001`
- Without date: `INV-1001`, `INV-1002`, etc.

**Format Placeholders**:
- `{date}` - Current date
- `{counter}` - Sequential counter
- `{prefix}` - Configured prefix

### 6. Receipt Business Details (receipt_business_details.txt)

Customize receipt header and footer.

**Location**: `assets/config/receipt_business_details.txt`

**Example Configuration**:
```json
{
  "businessName": "Your Store Name",
  "businessAddress": "123 Main Street, City, State 12345",
  "businessPhone": "+1-234-567-8900",
  "businessEmail": "info@yourstore.com",
  "businessTaxId": "TAX123456789",
  "receiptHeader": "Thank you for your purchase!",
  "receiptFooter": "Visit us again!",
  "showLogo": true,
  "showTaxId": true,
  "showPhoneEmail": true,
  "paperWidth": "80mm"
}
```

**Receipt Settings**:
- `businessName` - Your company name
- `businessAddress` - Full business address
- `businessPhone` - Contact phone number
- `businessEmail` - Business email address
- `businessTaxId` - Tax registration number/GST ID
- `receiptHeader` - Message at top of receipt
- `receiptFooter` - Message at bottom
- `showLogo` - Display business logo
- `showTaxId` - Show tax ID on receipt
- `showPhoneEmail` - Show contact details
- `paperWidth` - Receipt paper width (58mm or 80mm for thermal printers)

## Runtime Configuration

### Database Configuration

**Database Location**:
- **Android**: `/data/data/com.yourapp.billing_guru/databases/billing_guru.db`
- **iOS**: `Documents/billing_guru.db`
- **Windows**: `AppData/Local/billing_guru/billing_guru.db`
- **Web**: IndexedDB (browser storage)

**Database Features**:
- Automatic initialization on first run
- Schema version management
- Migration support

**Configuration in Code**:
```dart
// In core/database/database_initializer.dart
Future<void> initializeDatabase() async {
  // Database setup
}
```

### Shared Preferences

**Configuration Storage**:
- Tax rates
- Receipt templates
- Currency settings
- Theme selection
- User preferences

**Access Pattern**:
```dart
final prefs = await SharedPreferences.getInstance();
await prefs.setString('default_tax_rate', '18.0');
String? taxRate = prefs.getString('default_tax_rate');
```

## Application Settings

### Accessing Configuration in Code

**Feature Flags**:
```dart
import 'package:billing_guru/core/config/app_features.dart';

bool isFeatureEnabled = AppFeatures.isFeatureEnabled('billing');
```

**Currency**:
```dart
import 'package:billing_guru/core/currency/currency_provider.dart';

// Access currency from Riverpod provider
final currencyNotifier = ref.read(currencyProvider.notifier);
await currencyNotifier.loadCurrencyFromAsset();
```

**Tax Rate**:
```dart
import 'package:billing_guru/core/tax/tax_rate_provider.dart';

// Access default tax rate
final taxRate = ref.watch(defaultTaxRateProvider);
```

**Receipt Template**:
```dart
import 'package:billing_guru/core/printing/receipt_template_provider.dart';

// Load saved receipt template
final template = ref.watch(receiptTemplateProvider);
```

## Theme Configuration

### Setting Color Theme

1. **In Settings UI**:
   - Navigate to Settings > Appearance
   - Select theme from dropdown
   - Changes apply immediately

2. **Programmatically**:
```dart
// Access AppColorTheme
await AppColorTheme.load();
var theme = AppColorTheme.currentTheme;
```

### Custom Theme Creation

To add a new custom theme:

1. Edit `assets/config/color_themes.json`
2. Add new theme object with unique ID
3. Define all color properties
4. Restart application
5. Theme appears in theme selector

## Modifying Configuration

### Editing Configuration Files

1. **Locate File**: Find configuration file in `assets/config/`
2. **Edit**: Open with text editor
3. **Format**: Ensure proper JSON/text format
4. **Save**: Save changes
5. **Reload**: Restart application to apply changes

### Updating at Runtime

Some settings can be updated at runtime through UI:

1. **Settings Screen**: 
   - Business Details
   - Tax Configuration
   - Currency Selection
   - Receipt Template
   - Payment Methods

2. **Persistence**:
   - Changes saved to SharedPreferences
   - Changes persist across app restarts

## Environment-Specific Configuration

For different environments, create separate configuration files:

1. **Development**: `assets/config/features.dev.json`
2. **Testing**: `assets/config/features.test.json`
3. **Production**: `assets/config/features.prod.json`

Load based on build flavor:
```dart
const String environment = String.fromEnvironment('FLAVOR', defaultValue: 'dev');
String configPath = 'assets/config/features.$environment.json';
```

## Troubleshooting Configuration

### Issue: Features not loading
- Check `features.json` syntax
- Verify file path in `pubspec.yaml` assets
- Restart application
- Check console for JSON parse errors

### Issue: Theme not applying
- Verify `color_themes.json` format
- Ensure color codes are valid hex values
- Restart application
- Check for color conflicts

### Issue: Currency not displaying correctly
- Verify `currency.txt` configuration
- Check decimal places setting
- Verify symbol and separators
- Restart application

### Issue: Invoice sequence resetting
- Check `invoice_sequence.txt` start number
- Verify database persists between sessions
- Check file permissions
- Ensure counter increments on each transaction

## Best Practices

1. **Backup Configuration**
   - Keep backup copies of config files
   - Version control configuration changes
   - Document any customizations

2. **Testing Changes**
   - Test configuration changes in development first
   - Verify with sample data
   - Check all affected features

3. **Performance**
   - Load configuration at startup only
   - Cache configuration values
   - Avoid frequent file reads

4. **Security**
   - Don't hardcode sensitive data
   - Use environment variables for secrets
   - Protect configuration files
   - Sanitize user input in settings

---

For more information, see [Getting Started](./01-getting-started.md) or [Features](./03-features.md).
