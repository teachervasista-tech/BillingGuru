import 'dart:io';

import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/database/migrations.dart';
import 'package:billing_guru/features/products/data/models/product.dart';
import 'package:billing_guru/features/products/data/product_category_service.dart';
import 'package:billing_guru/features/products/data/services/product_local_service.dart';
import 'package:billing_guru/features/products/presentation/widgets/product_categories_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'helpers/test_container.dart';

Product _product(String id, String category, {bool active = true}) => Product(
  id: id,
  shortCode: id.toUpperCase(),
  barcode: '',
  name: id,
  category: category,
  priceCents: 100,
  taxRate: 5,
  stockQuantity: 1,
  isActive: active,
);

void main() {
  late AppDatabase database;
  late ProductCategoryService categories;
  late ProductLocalService products;

  setUp(() {
    database = createTestDatabase();
    categories = ProductCategoryService(database: database);
    products = ProductLocalService(database: database);
  });
  tearDown(() => database.close());

  Future<List<String>> names() async =>
      (await categories.getCategories()).map((c) => c.name).toList();

  Future<String> categoryOf(String productId) async {
    final db = await database.database;
    return (await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [productId],
        )).single['category']
        as String;
  }

  test('upgrade seeds categories from existing products', () async {
    sqfliteFfiInit();
    final dir = await Directory.systemTemp.createTemp('bg_pcat_');
    addTearDown(() => dir.delete(recursive: true));
    final path = p.join(dir.path, 'v6.db');
    final legacy = await databaseFactoryFfiNoIsolate.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 6,
        onCreate: (db, _) async {
          await createBaselineSchema(db);
          await runMigrations(db, from: baselineSchemaVersion, to: 6);
          for (final (id, cat) in [
            ('a', 'Snacks'),
            ('b', 'drinks'),
            ('c', 'Snacks'),
          ]) {
            await db.insert('products', {
              'id': id,
              'short_code': id,
              'name': id,
              'category': cat,
              'price_cents': 1,
              'tax_rate': 0,
              'stock_quantity': 0,
            });
          }
        },
      ),
    );
    await legacy.close();

    final upgraded = AppDatabase.forTesting(databaseFactoryFfiNoIsolate, path);
    final seeded = await ProductCategoryService(database: upgraded)
        .getCategories();
    expect(seeded.map((c) => c.name), ['drinks', 'Snacks', 'Other']);
    expect(seeded.firstWhere((c) => c.name == 'Snacks').productCount, 2);
    await upgraded.close();
  });

  test(
    'saving a product creates its category, matching case-insensitively',
    () async {
      await products.insertProduct(_product('chips', 'Snacks'));
      await products.insertProduct(_product('nuts', 'snacks'));

      expect(await names(), containsAll(['Snacks']));
      expect(
        (await names()).where((n) => n.toLowerCase() == 'snacks').length,
        1,
      );
      expect(await categoryOf('nuts'), 'Snacks');
    },
  );

  test('rename applies to products; duplicate names are rejected', () async {
    await products.insertProduct(_product('chips', 'Snacks'));
    final snacks = (await categories.getCategories()).firstWhere(
      (c) => c.name == 'Snacks',
    );

    await categories.update(snacks, name: 'Savoury', color: 0xFF000000);
    expect(await categoryOf('chips'), 'Savoury');
    expect(await names(), contains('Savoury'));

    await categories.add('Drinks', 0xFF111111);
    final savoury = (await categories.getCategories()).firstWhere(
      (c) => c.name == 'Savoury',
    );
    expect(
      () => categories.update(savoury, name: 'drinks', color: 0),
      throwsA(isA<CategoryException>()),
    );
  });

  test('reorder changes the display order', () async {
    await categories.add('Drinks', 0);
    await categories.add('Bakery', 0);
    final before = await names();
    final bakery = (await categories.getCategories()).last;
    await categories.move(bakery.id, -1);
    final after = await names();
    expect(after.last, before[before.length - 2]);
    expect(after[after.length - 2], 'Bakery');
  });

  test(
    'delete moves products (incl. inactive) to the chosen category',
    () async {
      await products.insertProduct(_product('chips', 'Snacks'));
      await products.insertProduct(_product('old', 'Snacks', active: false));
      final snacks = (await categories.getCategories()).firstWhere(
        (c) => c.name == 'Snacks',
      );

      expect(
        () => categories.delete(snacks),
        throwsA(isA<CategoryException>()),
        reason: 'products need a new category',
      );
      await categories.delete(snacks, moveProductsTo: 'Other');

      expect(await names(), isNot(contains('Snacks')));
      expect(await categoryOf('chips'), 'Other');
      expect(await categoryOf('old'), 'Other');
    },
  );

  testWidgets('settings tab adds and renames a category', (tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    rootBundle.clear();

    final container = await createTestContainer(
      database: database,
      user: testAdmin,
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: ProductCategoriesTab())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addProductCategory')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('categoryNameField')), 'Fruit');
    await tester.tap(find.byKey(const Key('categorySaveButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pcat-Fruit')), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('pcat-Fruit')),
        matching: find.byTooltip('Edit'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('categoryNameField')),
      'Fresh fruit',
    );
    await tester.tap(find.byKey(const Key('categorySaveButton')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pcat-Fresh fruit')), findsOneWidget);
    expect(await names(), contains('Fresh fruit'));
  });
}
