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
      orderBy: 'name ASC',
    );

    return rows.map(ProductMapper.fromMap).toList();
  }

  Future<List<Product>> searchProducts(String query) async {
    final db = await database.database;

    final searchText = query.trim();

    if (searchText.isEmpty) {
      return getAllProducts();
    }

    final rows = await db.query(
      'products',
      where: '''
        is_active = ?
        AND (name LIKE ? OR barcode LIKE ?)
      ''',
      whereArgs: [1, '%$searchText%', '%$searchText%'],
      orderBy: 'name ASC',
    );

    return rows.map(ProductMapper.fromMap).toList();
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final db = await database.database;

    final rows = await db.query(
      'products',
      where: 'barcode = ? AND is_active = ?',
      whereArgs: [barcode, 1],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return ProductMapper.fromMap(rows.first);
  }

  Future<void> insertProduct(Product product) async {
    final db = await database.database;

    await db.insert(
      'products',
      ProductMapper.toMap(product),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }
}
