# BillingGuru Architecture

Overview of BillingGuru's technical architecture and design patterns.

## Architecture Overview

BillingGuru follows a clean, layered architecture pattern with clear separation of concerns.

### High-Level Architecture

```
┌─────────────────────────────────────────┐
│         Presentation Layer              │
│    (UI Screens, Widgets, State)         │
├─────────────────────────────────────────┤
│      Domain Layer                       │
│  (Entities, Use Cases, Interfaces)      │
├─────────────────────────────────────────┤
│       Data Layer                        │
│ (Repositories, Models, Data Sources)    │
├─────────────────────────────────────────┤
│       Core Layer                        │
│  (Config, Database, Services)           │
└─────────────────────────────────────────┘
```

## Directory Structure

```
lib/
├── main.dart                    # Application entry point
│
├── app/                         # Application-level code
│   ├── app.dart                # Main app widget
│   ├── theme.dart              # Theme configuration
│   ├── router/                 # Route definitions (GoRouter)
│   │   └── router.dart
│   ├── navigation/             # Navigation logic
│   │   └── nav_provider.dart
│   ├── screens/                # Full-page screens
│   │   └── splash_screen.dart
│   └── widgets/                # App-level shared widgets
│       └── app_drawer.dart
│
├── core/                        # Core utilities and services
│   ├── config/                 # Configuration management
│   │   ├── app_features.dart  # Feature flags
│   │   └── app_constants.dart
│   ├── database/              # Database layer
│   │   ├── app_database.dart
│   │   ├── database_initializer.dart
│   │   └── schema.dart
│   ├── currency/              # Currency handling
│   │   └── currency_provider.dart
│   ├── tax/                   # Tax calculations
│   │   └── tax_rate_provider.dart
│   ├── printing/              # Receipt printing
│   │   ├── printing_service.dart
│   │   └── receipt_template_provider.dart
│   ├── storage/               # Local storage utilities
│   │   └── storage_service.dart
│   └── barcode/               # Barcode scanning
│       └── barcode_scanner.dart
│
└── features/                    # Feature modules (Clean Architecture)
    ├── cart/                   # Shopping cart feature
    │   ├── domain/             # Domain layer
    │   │   ├── entities/
    │   │   │   └── cart_item.dart
    │   │   └── repositories/
    │   │       └── cart_repository.dart
    │   ├── data/               # Data layer
    │   │   ├── models/
    │   │   │   └── cart_item_model.dart
    │   │   └── repositories/
    │   │       └── cart_repository_impl.dart
    │   └── presentation/       # Presentation layer
    │       ├── screens/
    │       │   └── cart_screen.dart
    │       ├── view_models/
    │       │   └── cart_provider.dart
    │       └── widgets/
    │           └── cart_item_widget.dart
    ├── checkout/
    ├── inventory/
    ├── products/
    ├── sales/
    ├── reports/
    ├── settings/
    ├── dashboard/
    └── home/
```

## Core Architectural Patterns

### 1. Clean Architecture

Each feature follows the Clean Architecture pattern with distinct layers:

**Domain Layer**:
- Business logic independent of frameworks
- Entities (core business objects)
- Repository interfaces (abstract contracts)
- No dependencies on Flutter/external packages

**Data Layer**:
- Repository implementations
- Models (data transfer objects)
- Data sources (local/remote)
- Implements domain repository interfaces

**Presentation Layer**:
- UI screens and widgets
- State management (Riverpod)
- View models/controllers
- Converts domain models to UI models

### 2. State Management: Riverpod

BillingGuru uses Riverpod for state management and dependency injection.

**Provider Types Used**:

```dart
// StateNotifier for complex state
final cartProvider = StateNotifierProvider<CartNotifier, CartState>(...);

// FutureProvider for async data
final productsProvider = FutureProvider<List<Product>>(...);

// StreamProvider for streams
final salesStreamProvider = StreamProvider<Sale>(...);

// StateProvider for simple state
final selectedCategoryProvider = StateProvider<String>(...);

// ChangeNotifierProvider for legacy patterns
final settingsProvider = ChangeNotifierProvider<Settings>(...);
```

**Key Providers**:
- `cartProvider` - Shopping cart state management
- `productsProvider` - Product inventory data
- `currencyProvider` - Currency configuration
- `defaultTaxRateProvider` - Tax rate state
- `receiptTemplateProvider` - Receipt formatting

### 3. Navigation: GoRouter

GoRouter manages all navigation throughout the app.

**Route Structure**:
```dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => HomeScreen(),
      routes: [
        GoRoute(
          path: 'billing',
          name: 'billing',
          builder: (context, state) => BillingScreen(),
        ),
      ],
    ),
  ],
);
```

**Navigation Methods**:
```dart
// Push navigation
context.pushNamed('billing');

// Replace navigation
context.goNamed('home');

// Pop navigation
context.pop();

// Navigation with parameters
context.pushNamed('detail', pathParameters: {'id': '123'});
```

### 4. Database Layer

SQLite database with sqflite for local data persistence.

**Database Features**:
- Version management and migrations
- Transaction support
- Schema initialization
- CRUD operations

**Key Entities**:
- Products
- Sales/Orders
- Cart Items
- Payment Methods
- Tax Rates
- Receipt Templates
- Business Settings

**Database Access**:
```dart
final database = await AppDatabase.instance.database;

// Insert
await database.insert('products', productMap);

// Query
final products = await database.query('products');

// Update
await database.update('products', productMap, where: 'id = ?', whereArgs: [id]);

// Delete
await database.delete('products', where: 'id = ?', whereArgs: [id]);
```

### 5. Dependency Injection

Riverpod handles dependency injection throughout the app.

**Provider Definition**:
```dart
// Service provider
final databaseProvider = Provider((ref) {
  return AppDatabase.instance;
});

// Repository provider
final productRepositoryProvider = Provider((ref) {
  final db = ref.watch(databaseProvider);
  return ProductRepositoryImpl(db);
});

// Use case/service provider
final productServiceProvider = Provider((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductService(repo);
});
```

## Key Components

### 1. Database Initializer

Initializes SQLite database on app startup.

**Responsibilities**:
- Create tables if not exists
- Run migrations
- Set up constraints and indexes
- Initialize default data

**Location**: `lib/core/database/database_initializer.dart`

### 2. Configuration Manager

Loads and manages application configuration.

**Managed Configuration**:
- Feature flags
- Currency settings
- Tax rates
- Business details
- Receipt templates
- Printer settings

**Loading**:
```dart
// In main.dart
await AppFeatures.load();
await AppColorTheme.load();
await currencyProvider.loadCurrencyFromAsset();
```

### 3. Printing Service

Handles receipt generation and printing.

**Features**:
- Receipt generation from templates
- Printer detection and selection
- PDF generation
- Print job management

**Usage**:
```dart
final printingService = ref.read(printingServiceProvider);
await printingService.printReceipt(receiptData);
```

### 4. Tax Calculator

Automatic tax calculation on sales.

**Features**:
- Default tax rate application
- Category-specific tax rates
- Rounding rules
- Tax display formatting

## Data Flow

### POS Billing Flow

```
User Input
    ↓
[Billing Screen] → Adds product to cart
    ↓
[Cart Provider] → Updates cart state
    ↓
[Cart Repository] → Persists cart data
    ↓
[SQLite Database] ← Stores transaction data
    ↓
[Checkout Flow] → Payment processing
    ↓
[Receipt Generation] → PDF/Print output
    ↓
[Sales Repository] → Records completed sale
    ↓
[Database] ← Persists sale transaction
```

### State Update Flow with Riverpod

```
UI Action
    ↓
StateNotifier.state = newState
    ↓
ref.watch(provider) notified
    ↓
Dependent widgets rebuild
    ↓
UI reflects new state
```

## Concurrency and Threading

**Async Operations**:
- Database operations run on background isolate
- Network requests (if any) use async/await
- File I/O (printing) non-blocking

**Background Processing**:
```dart
// Using Future
Future.microtask(() { /* run soon */ });

// Using Isolate (if needed)
await Isolate.run(() { /* heavy computation */ });
```

## Error Handling

**Error Handling Pattern**:
```dart
try {
  final result = await repository.fetchData();
  return result;
} on RepositoryException catch (e) {
  // Handle known errors
  return error;
} catch (e) {
  // Handle unexpected errors
  rethrow;
}
```

**Error Display**:
- Snackbars for transient errors
- Dialogs for critical errors
- Error states in UI

## Performance Considerations

### 1. Lazy Loading
- Products loaded on demand
- Reports generated asynchronously
- Charts rendered with data pagination

### 2. Caching
- Riverpod caches provider results
- Database queries cached in memory
- Configuration loaded once at startup

### 3. Optimization
- Efficient database queries with indexes
- Widget rebuilds minimized with proper dependency
- Asset loading optimized with bundling

## Testing Architecture

**Testing Structure**:
```
test/
├── unit/
│   ├── core/
│   └── features/
├── widget/
│   └── features/
└── integration/
    └── flows/
```

**Testing Providers**:
```dart
// Override providers in tests
final container = ProviderContainer(
  overrides: [
    databaseProvider.overrideWithValue(mockDatabase),
  ],
);
```

## Build Variants

### Development Build
- Debug symbols included
- Assertions enabled
- Full logging

### Release Build
- Optimized size and performance
- Assertions disabled
- Minified code
- Obfuscated (optional)

## Platform-Specific Code

**Conditional Compilation**:
```dart
import 'package:flutter/foundation.dart';

if (kIsWeb) {
  // Web-specific code
} else if (defaultTargetPlatform == TargetPlatform.windows) {
  // Windows-specific code
}
```

**Platform Channels** (if needed):
- Android/iOS: Method channels
- Windows/macOS: Platform channels
- Web: JavaScript interop

## Security Architecture

### Data Security
- Local database (not encrypted - future improvement)
- Sensitive data not logged
- Configuration files secured in asset bundle

### Input Validation
- User input sanitized
- Barcode codes validated
- Transaction amounts verified

---

For detailed information about specific components, see [Database Schema](./06-database-schema.md) or [API Reference](./07-api-reference.md).
