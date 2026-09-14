import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/product.dart';
import '../models/product_mapper.dart';

class ProductLocalService {
  ProductLocalService({required this.database});

  final AppDatabase database;

  Future<List<Product>> getAllProducts() async {
    final db = await database.database;

    final rows = await db.query(
      'products',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(ProductMapper.fromMap).toList();
  }

  Future<List<Product>> searchProducts(String query, {String? category}) async {
    final db = await database.database;

    final searchText = query.trim();
    final conditions = <String>['is_active = ?'];
    final arguments = <Object?>[1];

    if (searchText.isNotEmpty) {
      conditions.add('(name LIKE ? OR barcode LIKE ?)');
      arguments.add('%$searchText%');
      arguments.add('%$searchText%');
    }

    if (category != null && category.isNotEmpty) {
      conditions.add('category = ?');
      arguments.add(category);
    }

    final rows = await db.query(
      'products',
      where: conditions.join(' AND '),
      whereArgs: arguments,
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(ProductMapper.fromMap).toList();
  }

  Future<List<String>> getActiveCategories() async {
    final db = await database.database;

    final rows = await db.rawQuery('''
    SELECT DISTINCT category
    FROM products
    WHERE is_active = 1
    ORDER BY category COLLATE NOCASE ASC
    ''');

    return rows
        .map((row) => row['category'] as String)
        .where((category) => category.trim().isNotEmpty)
        .toList();
  }

  Future<Map<String, int>> getActiveCategoryCounts() async {
    final db = await database.database;

    final rows = await db.rawQuery('''
    SELECT category, COUNT(*) AS product_count
    FROM products
    WHERE is_active = 1
    GROUP BY category
    ORDER BY category COLLATE NOCASE ASC
    ''');

    return {
      for (final row in rows)
        row['category'] as String: row['product_count'] as int,
    };
  }

  Future<Product?> getProductById(String id) async {
    final db = await database.database;

    final rows = await db.query(
      'products',
      where: 'id = ? AND is_active = ?',
      whereArgs: [id, 1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProductMapper.fromMap(rows.first);
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database.database;

    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = ?',
      whereArgs: [barcode.trim(), 1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProductMapper.fromMap(rows.first);
  }

  Future<void> insertProduct(Product product) async {
    final db = await database.database;

    final existingProduct = await db.query(
      'products',
      columns: ['id'],
      where: 'barcode = ?',
      whereArgs: [product.barcode],
      limit: 1,
    );

    if (existingProduct.isNotEmpty) {
      throw Exception(
        'A product with barcode ${product.barcode} already exists.',
      );
    }

    await db.insert(
      'products',
      ProductMapper.toMap(product),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<void> updateProduct(Product product) async {
    final db = await database.database;

    final duplicateBarcode = await db.query(
      'products',
      columns: ['id'],
      where: 'barcode = ? AND id != ?',
      whereArgs: [product.barcode, product.id],
      limit: 1,
    );

    if (duplicateBarcode.isNotEmpty) {
      throw Exception(
        'A different product already uses barcode ${product.barcode}.',
      );
    }

    final updatedRows = await db.update(
      'products',
      ProductMapper.toMap(product),
      where: 'id = ?',
      whereArgs: [product.id],
    );

    if (updatedRows == 0) {
      throw Exception('Product ${product.id} was not found.');
    }
  }

  Future<void> deactivateProduct(String productId) async {
    final db = await database.database;

    final updatedRows = await db.update(
      'products',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [productId],
    );

    if (updatedRows == 0) {
      throw Exception('Product $productId was not found.');
    }
  }

  Future<void> activateProduct(String productId) async {
    final db = await database.database;

    final updatedRows = await db.update(
      'products',
      {'is_active': 1},
      where: 'id = ? AND is_active = ?',
      whereArgs: [productId, 0],
    );

    if (updatedRows == 0) {
      throw Exception('Inactive product $productId was not found.');
    }
  }

  Future<List<Product>> getInactiveProducts({String search = ''}) async {
    final db = await database.database;
    final trimmedSearch = search.trim();

    final rows = await db.query(
      'products',
      where: trimmedSearch.isEmpty
          ? 'is_active = ?'
          : '''
          is_active = ?
          AND (
            name LIKE ?
            OR barcode LIKE ?
          )
        ''',
      whereArgs: trimmedSearch.isEmpty
          ? [0]
          : [0, '%$trimmedSearch%', '%$trimmedSearch%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );

    return rows.map(ProductMapper.fromMap).toList();
  }
}
