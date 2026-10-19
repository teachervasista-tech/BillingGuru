import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/inventory_item.dart';

class InventoryLocalService {
  InventoryLocalService({required this.database});

  final AppDatabase database;

  Future<List<InventoryItem>> getInventory({
    String search = '',
    bool includeInactive = false,
  }) async {
    final db = await database.database;
    final trimmedSearch = search.trim();

    final conditions = <String>[];
    final arguments = <Object?>[];

    if (!includeInactive) {
      conditions.add('p.is_active = ?');
      arguments.add(1);
    }

    if (trimmedSearch.isNotEmpty) {
      conditions.add('(p.name LIKE ? OR p.barcode LIKE ?)');
      arguments.add('%$trimmedSearch%');
      arguments.add('%$trimmedSearch%');
    }

    final rows = await db.rawQuery('''
      SELECT
        p.id,
        p.name,
        p.category,
        p.barcode,
        p.stock_quantity,
        p.price_cents,
        p.is_active
      FROM products p
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY p.name COLLATE NOCASE ASC
      ''', arguments);

    return rows.map(_fromMap).toList();
  }

  Future<void> increaseStock({
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    final db = await database.database;

    await db.transaction((transaction) async {
      final result = await transaction.rawUpdate(
        '''
        UPDATE products
        SET stock_quantity = stock_quantity + ?
        WHERE id = ? AND is_active = 1
        ''',
        [quantity, productId],
      );

      if (result == 0) {
        throw Exception('Active product was not found.');
      }

      await transaction.insert('stock_movements', {
        'id': _movementId(productId, 'in'),
        'product_id': productId,
        'movement_type': 'purchase',
        'quantity': quantity,
        'reference_id': null,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  Future<void> decreaseStock({
    required String productId,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    final db = await database.database;

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'products',
        columns: ['stock_quantity'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [productId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('Active product was not found.');
      }

      final currentStock = rows.first['stock_quantity'] as int;

      if (currentStock < quantity) {
        throw Exception('Cannot reduce stock below zero.');
      }

      await transaction.update(
        'products',
        {'stock_quantity': currentStock - quantity},
        where: 'id = ?',
        whereArgs: [productId],
      );

      await transaction.insert('stock_movements', {
        'id': _movementId(productId, 'out'),
        'product_id': productId,
        'movement_type': 'adjustment',
        'quantity': -quantity,
        'reference_id': null,
        'created_at': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    });
  }

  InventoryItem _fromMap(Map<String, Object?> map) {
    return InventoryItem(
      productId: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String? ?? 'Other',
      barcode: map['barcode'] as String? ?? '',
      stockQuantity: map['stock_quantity'] as int,
      priceCents: map['price_cents'] as int,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  String _movementId(String productId, String direction) {
    return '$productId-$direction-'
        '${DateTime.now().microsecondsSinceEpoch}';
  }
}
