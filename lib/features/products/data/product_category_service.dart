import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/migrations.dart';
import '../../../core/database/row_reader.dart';

class ProductCategory {
  const ProductCategory({
    required this.id,
    required this.name,
    required this.color,
    this.sortOrder = 0,
    this.isActive = true,
    this.productCount = 0,
  });

  final String id;
  final String name;

  /// ARGB color value.
  final int color;
  final int sortOrder;

  /// Archived categories are not offered for new or edited products.
  final bool isActive;

  /// Active products in this category.
  final int productCount;

  factory ProductCategory.fromMap(Map<String, Object?> map) => ProductCategory(
    id: map.stringOf('id'),
    name: map.stringOf('name'),
    color: map.intOf('color'),
    sortOrder: map.intOf('sort_order'),
    isActive: map.boolOf('is_active', true),
    productCount: map.intOf('product_count'),
  );
}

class CategoryException implements Exception {
  const CategoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Managed product categories. Products keep the category *name*; renaming
/// a category renames it on its products too.
class ProductCategoryService {
  ProductCategoryService({required this.database});

  final AppDatabase database;
  static const _uuid = Uuid();

  Future<List<ProductCategory>> getCategories({bool activeOnly = false}) async {
    final db = await database.database;
    final rows = await db.rawQuery('''
      SELECT c.*, COUNT(p.id) AS product_count
      FROM product_categories c
      LEFT JOIN products p
        ON p.category = c.name COLLATE NOCASE AND p.is_active = 1
      ${activeOnly ? 'WHERE c.is_active = 1' : ''}
      GROUP BY c.id
      ORDER BY c.sort_order ASC, c.name COLLATE NOCASE ASC
    ''');
    return rows.map(ProductCategory.fromMap).toList();
  }

  /// Returns the canonical name for [name], creating the category if it does
  /// not exist yet (used when saving or importing products).
  static Future<String> ensure(DatabaseExecutor db, String name) async {
    final trimmed = name.trim().isEmpty ? defaultProductCategory : name.trim();
    final existing = await db.query(
      'product_categories',
      columns: ['name'],
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [trimmed],
      limit: 1,
    );
    if (existing.isNotEmpty) return existing.first.stringOf('name');

    final next = (await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM product_categories',
    )).first.intOf('n');
    await db.insert('product_categories', {
      'id': _uuid.v4(),
      'name': trimmed,
      'color': categoryPalette[next % categoryPalette.length],
      'sort_order': next,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    return trimmed;
  }

  Future<void> add(String name, int color) async {
    final db = await database.database;
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const CategoryException('Enter a name.');
    if (await _nameTaken(db, trimmed)) {
      throw CategoryException('"$trimmed" already exists.');
    }
    final next = (await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS n FROM product_categories',
    )).first.intOf('n');
    await db.insert('product_categories', {
      'id': _uuid.v4(),
      'name': trimmed,
      'color': color,
      'sort_order': next,
    });
  }

  /// Updates name/color; a rename is applied to the category's products.
  Future<void> update(
    ProductCategory category, {
    required String name,
    required int color,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw const CategoryException('Enter a name.');
    final db = await database.database;
    await db.transaction((txn) async {
      if (trimmed.toLowerCase() != category.name.toLowerCase() &&
          await _nameTaken(txn, trimmed)) {
        throw CategoryException('"$trimmed" already exists.');
      }
      await txn.update(
        'product_categories',
        {'name': trimmed, 'color': color},
        where: 'id = ?',
        whereArgs: [category.id],
      );
      if (trimmed != category.name) {
        await txn.rawUpdate(
          'UPDATE products SET category = ? WHERE category = ? COLLATE NOCASE',
          [trimmed, category.name],
        );
      }
    });
  }

  Future<void> setActive(String id, bool active) async {
    final db = await database.database;
    await db.update(
      'product_categories',
      {'is_active': active ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Moves a category one place up (-1) or down (+1) in the display order.
  Future<void> move(String id, int direction) async {
    final categories = await getCategories();
    final index = categories.indexWhere((c) => c.id == id);
    final target = index + direction;
    if (index < 0 || target < 0 || target >= categories.length) return;
    final reordered = [...categories];
    final item = reordered.removeAt(index);
    reordered.insert(target, item);
    final db = await database.database;
    await db.transaction((txn) async {
      for (var i = 0; i < reordered.length; i++) {
        await txn.update(
          'product_categories',
          {'sort_order': i},
          where: 'id = ?',
          whereArgs: [reordered[i].id],
        );
      }
    });
  }

  /// Deletes the category, moving all its products (active and inactive)
  /// to [moveProductsTo].
  Future<void> delete(
    ProductCategory category, {
    String? moveProductsTo,
  }) async {
    final db = await database.database;
    await db.transaction((txn) async {
      final remaining = (await txn.rawQuery(
        'SELECT COUNT(*) AS n FROM product_categories WHERE id != ?',
        [category.id],
      )).first.intOf('n');
      if (remaining == 0) {
        throw const CategoryException('At least one category is required.');
      }
      final used = (await txn.rawQuery(
        'SELECT COUNT(*) AS n FROM products WHERE category = ? COLLATE NOCASE',
        [category.name],
      )).first.intOf('n');
      if (used > 0) {
        if (moveProductsTo == null ||
            moveProductsTo.toLowerCase() == category.name.toLowerCase()) {
          throw const CategoryException(
            'Choose another category for its products.',
          );
        }
        final target = await ensure(txn, moveProductsTo);
        await txn.rawUpdate(
          'UPDATE products SET category = ? WHERE category = ? COLLATE NOCASE',
          [target, category.name],
        );
      }
      await txn.delete(
        'product_categories',
        where: 'id = ?',
        whereArgs: [category.id],
      );
    });
  }

  Future<bool> _nameTaken(DatabaseExecutor db, String name) async {
    final rows = await db.query(
      'product_categories',
      columns: ['id'],
      where: 'name = ? COLLATE NOCASE',
      whereArgs: [name],
      limit: 1,
    );
    return rows.isNotEmpty;
  }
}
