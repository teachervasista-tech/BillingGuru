import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/migrations.dart';
import '../../../checkout/domain/payment.dart';
import '../../../expenses/domain/expense.dart';
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
        p.cost_price_cents,
        p.is_active
      FROM products p
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY p.name COLLATE NOCASE ASC
      ''', arguments);

    return rows.map(_fromMap).toList();
  }

  /// Adds stock. When [unitCostCents] is given the product's cost price
  /// becomes the weighted average of existing and received stock, and with
  /// [recordExpense] a linked "Stock purchase" expense is created.
  Future<void> increaseStock({
    required String productId,
    required int quantity,
    int? unitCostCents,
    String? supplier,
    bool recordExpense = false,
    PaymentMethod paymentMethod = PaymentMethod.cash,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    if (unitCostCents != null && unitCostCents < 0) {
      throw ArgumentError('Unit cost cannot be negative.');
    }

    final db = await database.database;
    final now = DateTime.now();

    await db.transaction((transaction) async {
      final rows = await transaction.query(
        'products',
        columns: ['name', 'stock_quantity', 'cost_price_cents'],
        where: 'id = ? AND is_active = 1',
        whereArgs: [productId],
        limit: 1,
      );

      if (rows.isEmpty) {
        throw Exception('Active product was not found.');
      }

      final row = rows.first;
      final oldStock = row['stock_quantity'] as int;
      final oldCost = row['cost_price_cents'] as int? ?? 0;
      var newCost = oldCost;
      if (unitCostCents != null) {
        newCost = oldStock > 0 && oldCost > 0
            ? ((oldStock * oldCost + quantity * unitCostCents) /
                      (oldStock + quantity))
                  .round()
            : unitCostCents;
      }

      await transaction.update(
        'products',
        {'stock_quantity': oldStock + quantity, 'cost_price_cents': newCost},
        where: 'id = ?',
        whereArgs: [productId],
      );

      String? expenseId;
      final totalCost = (unitCostCents ?? 0) * quantity;
      if (recordExpense && totalCost > 0) {
        final expense = Expense(
          id: 'exp-${_movementId(productId, 'in')}',
          categoryId: stockPurchaseCategoryId,
          amountCents: totalCost,
          paymentMethod: paymentMethod,
          vendor: supplier,
          note: '${row['name']} x $quantity',
          expenseDate: now,
          createdAt: now,
        );
        await transaction.insert('expenses', expense.toMap());
        expenseId = expense.id;
      }

      await transaction.insert('stock_movements', {
        'id': _movementId(productId, 'in'),
        'product_id': productId,
        'movement_type': 'purchase',
        'quantity': quantity,
        'reference_id': null,
        'created_at': now.toIso8601String(),
        'unit_cost_cents': unitCostCents,
        'supplier': (supplier?.trim().isEmpty ?? true)
            ? null
            : supplier!.trim(),
        'expense_id': expenseId,
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
      costPriceCents: map['cost_price_cents'] as int? ?? 0,
      isActive: (map['is_active'] as int) == 1,
    );
  }

  String _movementId(String productId, String direction) {
    return '$productId-$direction-'
        '${DateTime.now().microsecondsSinceEpoch}';
  }
}
