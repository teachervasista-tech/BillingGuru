# BillingGuru Development Guide

Guide for developers working on the BillingGuru codebase.

## Development Environment Setup

### Prerequisites

1. **Flutter SDK** (3.13.2 or higher)
   ```bash
   flutter --version
   ```

2. **Dart SDK** (included with Flutter)
   ```bash
   dart --version
   ```

3. **IDE Setup**:
   - **VS Code**: Install Flutter and Dart extensions
   - **Android Studio**: Install Flutter and Dart plugins
   - **IntelliJ IDEA**: Install Flutter plugin

4. **Platform-Specific Tools**:
   - **Windows**: Visual Studio Build Tools or Community Edition
   - **macOS**: Xcode 12+
   - **Android**: Android Studio or Android SDK CLI
   - **iOS**: Xcode 12+

### Initial Setup

1. Clone repository:
   ```bash
   git clone <repository-url>
   cd BillingGuru
   ```

2. Get dependencies:
   ```bash
   flutter pub get
   ```

3. Run code generator (if applicable):
   ```bash
   dart run build_runner build
   ```

4. Run analysis:
   ```bash
   flutter analyze
   ```

5. Format code:
   ```bash
   dart format lib
   ```

## Project Structure

```
lib/
├── main.dart                      # App entry point
├── app/                           # Application layer
│   ├── app.dart                  # App widget and config
│   ├── theme.dart                # Material theme
│   ├── router/                   # Navigation routes
│   ├── navigation/               # Navigation logic
│   ├── screens/                  # Full screens
│   └── widgets/                  # Shared widgets
├── core/                         # Core functionality
│   ├── config/                   # App configuration
│   ├── database/                 # Database access
│   ├── currency/                 # Currency handling
│   ├── printing/                 # Receipt printing
│   ├── storage/                  # File storage
│   ├── tax/                      # Tax calculations
│   └── barcode/                  # Barcode scanning
└── features/                     # Feature modules
    ├── cart/                     # Shopping cart
    ├── checkout/                 # Payment processing
    ├── inventory/                # Product inventory
    ├── products/                 # Product management
    ├── sales/                    # Sales tracking
    ├── reports/                  # Reporting/analytics
    ├── settings/                 # App settings
    ├── dashboard/                # Dashboard display
    └── home/                     # Home screen
```

## Code Style & Conventions

### Dart/Flutter Style Guide

Follow [Effective Dart](https://dart.dev/guides/language/effective-dart):

1. **Naming**:
   ```dart
   // Classes and types: UpperCamelCase
   class ShoppingCart { }
   
   // Variables and functions: lowerCamelCase
   String productName = "Coffee";
   void addToCart() { }
   
   // Constants: lowerCamelCase
   const defaultTaxRate = 18.0;
   ```

2. **File Naming**:
   ```
   // Files: snake_case.dart
   cart_provider.dart
   product_model.dart
   billing_screen.dart
   ```

3. **Imports**:
   ```dart
   // Organize imports: dart, flutter, packages, relative
   import 'dart:async';
   import 'package:flutter/material.dart';
   import 'package:billing_guru/core/database/app_database.dart';
   import '../models/product.dart';
   ```

### Documentation

1. **Class Documentation**:
   ```dart
   /// Manages shopping cart state and operations.
   /// 
   /// Handles adding/removing items, calculating totals,
   /// and applying discounts.
   class CartNotifier extends StateNotifier<CartState> {
   }
   ```

2. **Method Documentation**:
   ```dart
   /// Adds a product to the cart with the specified quantity.
   /// 
   /// Returns the updated cart state after adding the item.
   /// Throws [ArgumentError] if quantity is negative.
   CartState addItem(Product product, int quantity) {
   }
   ```

3. **No Comments for Obvious Code**:
   ```dart
   // ❌ Bad: Comment explains what the code does
   // Increment the counter
   counter++;
   
   // ✅ Good: Self-explanatory code
   cartItemCount++;
   ```

### Formatting

1. **Run formatter**:
   ```bash
   dart format lib
   ```

2. **Line length**: Max 80-100 characters

3. **Indentation**: 2 spaces (not tabs)

## Development Workflow

### 1. Creating a New Feature

**Step 1: Plan Structure**
- Create feature directory: `lib/features/feature_name/`
- Set up domain, data, and presentation layers
- Define models and repositories

**Step 2: Create Models**
```dart
// lib/features/feature_name/domain/entities/entity.dart
class Entity {
  final String id;
  final String name;
  
  Entity({required this.id, required this.name});
}
```

**Step 3: Create Repository Interface**
```dart
// lib/features/feature_name/domain/repositories/repository.dart
abstract class EntityRepository {
  Future<List<Entity>> getEntities();
  Future<Entity> getById(String id);
  Future<void> save(Entity entity);
  Future<void> delete(String id);
}
```

**Step 4: Implement Repository**
```dart
// lib/features/feature_name/data/repositories/repository_impl.dart
class EntityRepositoryImpl implements EntityRepository {
  final Database database;
  
  EntityRepositoryImpl(this.database);
  
  @override
  Future<List<Entity>> getEntities() async {
    final result = await database.query('entities');
    return result.map((e) => Entity.fromMap(e)).toList();
  }
  
  // Implement other methods
}
```

**Step 5: Create Riverpod Providers**
```dart
// lib/features/feature_name/presentation/providers/entity_provider.dart
final entityProvider = FutureProvider<List<Entity>>((ref) async {
  final repository = ref.read(entityRepositoryProvider);
  return repository.getEntities();
});

final entityRepositoryProvider = Provider<EntityRepository>((ref) {
  final db = ref.read(databaseProvider);
  return EntityRepositoryImpl(db);
});
```

**Step 6: Create UI Screens/Widgets**
```dart
// lib/features/feature_name/presentation/screens/entity_list_screen.dart
class EntityListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entities = ref.watch(entityProvider);
    
    return entities.when(
      data: (items) => ListView(children: items.map((e) => Text(e.name)).toList()),
      loading: () => CircularProgressIndicator(),
      error: (err, st) => Text('Error: $err'),
    );
  }
}
```

### 2. Working with Database

**Add New Table**:
1. Update `lib/core/database/schema.dart`
2. Add CREATE TABLE SQL
3. Increment database version
4. Add migration in `onUpgrade`
5. Create model class
6. Create repository for table

**Query Data**:
```dart
final db = ref.read(databaseProvider);
final result = await db.query(
  'products',
  where: 'category_id = ?',
  whereArgs: [categoryId],
  orderBy: 'name ASC',
);
```

**Insert/Update/Delete**:
```dart
// Insert
await db.insert('products', productMap);

// Update
await db.update('products', productMap, where: 'id = ?', whereArgs: [id]);

// Delete
await db.delete('products', where: 'id = ?', whereArgs: [id]);
```

### 3. State Management with Riverpod

**Provider Types**:

```dart
// Simple provider
final themeProvider = Provider((ref) => AppTheme());

// State provider (mutable)
final counterProvider = StateProvider((ref) => 0);

// StateNotifier provider (complex state)
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// FutureProvider (async)
final productsProvider = FutureProvider<List<Product>>((ref) async {
  return await ref.read(productRepositoryProvider).getProducts();
});

// StreamProvider (continuous async)
final salesStreamProvider = StreamProvider<Sale>((ref) async* {
  yield* ref.read(salesRepositoryProvider).watchSales();
});

// Family provider (parameterized)
final productProvider = FutureProvider.family<Product, String>((ref, id) async {
  return await ref.read(productRepositoryProvider).getById(id);
});
```

**In Widgets**:
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch a provider (rebuild on change)
    final cart = ref.watch(cartProvider);
    
    // Modify state
    cart.addItem(product);
    
    // One-time read
    final repo = ref.read(productRepositoryProvider);
    
    // Listen to changes
    ref.listen(cartProvider, (previous, next) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Items changed')),
      );
    });
    
    return Scaffold(
      body: Text('Cart: ${cart.items.length}'),
    );
  }
}
```

### 4. Navigation

**Define Routes**:
```dart
// lib/app/router/router.dart
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'products/:id',
          name: 'product-detail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            return ProductDetailScreen(productId: id);
          },
        ),
      ],
    ),
  ],
);
```

**Navigate**:
```dart
// Push navigation (adds to stack)
context.pushNamed('product-detail', pathParameters: {'id': '123'});

// Replace navigation (replaces current screen)
context.goNamed('home');

// Pop (go back)
context.pop();

// Pop with result
Navigator.pop(context, result);
```

### 5. Error Handling

**Define Exceptions**:
```dart
class AppException implements Exception {
  final String message;
  final dynamic originalException;
  
  AppException(this.message, [this.originalException]);
  
  @override
  String toString() => message;
}

class DatabaseException extends AppException {}
class ValidationException extends AppException {}
class NetworkException extends AppException {}
```

**Handle Errors**:
```dart
try {
  final product = await repository.getProduct(id);
  return product;
} on DatabaseException catch (e) {
  logger.e('Database error: $e');
  throw DatabaseException('Failed to fetch product: ${e.message}');
} on Exception catch (e) {
  logger.e('Unexpected error: $e');
  throw AppException('Unexpected error: $e');
}
```

## Testing

### Unit Tests

**Location**: `test/unit/`

```dart
// test/unit/models/product_test.dart
import 'package:test/test.dart';
import 'package:billing_guru/features/products/domain/entities/product.dart';

void main() {
  group('Product', () {
    test('creates product with valid data', () {
      final product = Product(
        id: '1',
        name: 'Coffee',
        sku: 'COFFEE-001',
        categoryId: 'cat1',
        unitPrice: 5.0,
      );
      
      expect(product.name, 'Coffee');
      expect(product.unitPrice, 5.0);
    });
    
    test('validates negative price', () {
      expect(
        () => Product(
          id: '1',
          name: 'Coffee',
          sku: 'COFFEE-001',
          categoryId: 'cat1',
          unitPrice: -5.0,
        ),
        throwsArgumentError,
      );
    });
  });
}
```

### Widget Tests

**Location**: `test/widget/`

```dart
// test/widget/screens/billing_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:billing_guru/features/cart/presentation/screens/billing_screen.dart';

void main() {
  group('BillingScreen', () {
    testWidgets('displays product list', (tester) async {
      await tester.pumpWidget(const BillingScreen());
      
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Add to Cart'), findsWidgets);
    });
    
    testWidgets('adds product to cart', (tester) async {
      await tester.pumpWidget(const BillingScreen());
      
      await tester.tap(find.text('Add to Cart').first);
      await tester.pumpAndSettle();
      
      expect(find.text('1'), findsOneWidget);
    });
  });
}
```

### Run Tests

```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/unit/models/product_test.dart

# Run with coverage
flutter test --coverage

# View coverage report
genhtml coverage/lcov.info -o coverage/html
```

## Performance Optimization

### 1. Widget Rebuilds

**Problem**: Unnecessary rebuilds due to poor provider design
```dart
// ❌ Bad: Entire state watched, triggers rebuild on any change
final cart = ref.watch(cartProvider);
Text(cart.totalAmount.toString());

// ✅ Good: Watch only the field needed
final totalAmount = ref.watch(
  cartProvider.select((cart) => cart.totalAmount)
);
Text(totalAmount.toString());
```

### 2. Database Queries

**Problem**: Inefficient queries
```dart
// ❌ Bad: Loads all products
final products = await db.query('products');
final filtered = products.where((p) => p['price'] > 100).toList();

// ✅ Good: Filter in SQL
final products = await db.query(
  'products',
  where: 'price > ?',
  whereArgs: [100],
);
```

### 3. List Rendering

**Problem**: Large lists rebuild from scratch
```dart
// ❌ Bad: All items rebuild
ListView(
  children: items.map((item) => ItemWidget(item)).toList(),
)

// ✅ Good: Only visible items rendered
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) => ItemWidget(items[index]),
)
```

### 4. Image Optimization

```dart
// Optimize large images
Image.network(
  url,
  cacheHeight: 200,
  cacheWidth: 200,
  fit: BoxFit.cover,
)
```

## Debugging Techniques

### 1. Print Debugging

```dart
print('Debug: $value');  // Console output
debugPrint('Debug: $value');  // Better for large strings
```

### 2. Logging

```dart
import 'dart:developer' as developer;

developer.log(
  'Event occurred',
  name: 'feature_name',
  error: exception,
  stackTrace: stackTrace,
);
```

### 3. Flutter DevTools

```bash
# Start DevTools
flutter pub global activate devtools
devtools

# Open in browser and connect to running app
```

**Features**:
- Widget Inspector: Inspect widget tree
- Performance: Track frame rendering
- Memory: Track memory usage
- Network: Monitor network requests
- Logging: View app logs

### 4. Conditional Breakpoints

In IDE:
1. Set breakpoint on line
2. Right-click breakpoint
3. Set condition (e.g., `productId == '123'`)
4. Breakpoint only triggers when condition true

## Code Quality

### Static Analysis

```bash
# Run analyzer
flutter analyze

# Fix issues
dart fix --apply

# Format code
dart format lib
```

### Lint Rules

**Enable strict linting** in `analysis_options.yaml`:
```yaml
linter:
  rules:
    - avoid_empty_else
    - avoid_print
    - avoid_relative_lib_imports
    - avoid_returning_null_for_future
    - camel_case_extensions
    - camel_case_types
    - cancel_subscriptions
    - close_sinks
    - comment_references
    - control_flow_in_finally
    - empty_statements
    - hash_and_equals
    - invariant_booleans
    - iterable_contains_unrelated_type
    - leading_newlines_in_multiline_strings
    - list_remove_unrelated_type
    - literal_only_boolean_expressions
    - no_adjacent_strings_in_list
    - no_duplicate_case_values
    - prefer_void_to_future_void
    - throw_in_finally
    - unnecessary_statements
    - unrelated_type_equality_checks
```

## Release & Build

### Development Build

```bash
flutter run -d windows  # or your platform
```

### Profile Build

```bash
flutter run --profile -d windows
# Better performance than debug, can profile
```

### Release Build

```bash
flutter build windows --release
```

## Useful Commands

```bash
# Clean build artifacts
flutter clean

# Get dependencies
flutter pub get

# Upgrade dependencies
flutter pub upgrade

# Check environment
flutter doctor -v

# Format code
dart format lib

# Run analysis
flutter analyze

# Generate code (if using build_runner)
dart run build_runner build --delete-conflicting-outputs

# Run tests
flutter test

# Generate coverage report
flutter test --coverage
```

## Git Workflow

### Branch Naming

```
feature/feature-name        # New features
fix/bug-description         # Bug fixes
refactor/area-name          # Refactoring
docs/doc-name              # Documentation
chore/task-description     # Maintenance tasks
```

### Commit Messages

```
feature: Add product search functionality

- Implement search UI
- Add search repository
- Write tests

Closes #123
```

### Pull Request Process

1. Create feature branch
2. Make changes
3. Run tests and analysis
4. Create pull request
5. Address review feedback
6. Merge after approval

---

For more information, see [Architecture](./05-architecture.md) or [API Reference](./07-api-reference.md).
