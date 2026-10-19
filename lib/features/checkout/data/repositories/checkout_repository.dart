import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../domain/invoice_sequence.dart';
import '../../domain/sale.dart';

class CheckoutRepository {
  CheckoutRepository({required this.database});

  final AppDatabase database;

  Future<String> nextInvoiceNumber(
    InvoiceSequenceReset reset,
    DateTime date,
  ) async {
    final db = await database.database;
    final prefix = reset.prefixFor(date);
    final rows = await db.rawQuery(
      '''
      SELECT MAX(CAST(SUBSTR(invoice_number, ?) AS INTEGER)) AS last_sequence
      FROM sales
      WHERE invoice_number LIKE ?
      ''',
      [prefix.length + 1, '$prefix%'],
    );
    final last = (rows.first['last_sequence'] as int?) ?? 0;
    return reset.format(date, last + 1);
  }

  Future<void> saveSale(Sale sale) async {
    final db = await database.database;

    await db.transaction((transaction) async {
      for (final item in sale.items) {
        final products = await transaction.query(
          'products',
          columns: ['stock_quantity'],
          where: 'id = ? AND is_active = ?',
          whereArgs: [item.productId, 1],
          limit: 1,
        );

        if (products.isEmpty) {
          throw Exception('Product not found: ${item.productId}');
        }

        final availableStock = products.first['stock_quantity'] as int;

        if (availableStock < item.quantity) {
          throw Exception('Insufficient stock for product: ${item.productId}');
        }
      }

      await transaction.insert('sales', {
        'id': sale.id,
        'invoice_number': sale.invoiceNumber,
        'subtotal_cents': sale.subtotalCents,
        'discount_cents': sale.discountCents,
        'tax_cents': sale.taxCents,
        'total_cents': sale.totalCents,
        'payment_method': sale.paymentMethod.name,
        'created_at': sale.createdAt.toIso8601String(),
        'sync_status': sale.syncStatus,
      }, conflictAlgorithm: ConflictAlgorithm.abort);

      for (final item in sale.items) {
        await transaction.insert('sale_items', {
          'id': item.id,
          'sale_id': item.saleId,
          'product_id': item.productId,
          'quantity': item.quantity,
          'unit_price_cents': item.unitPriceCents,
          'total_cents': item.totalCents,
        }, conflictAlgorithm: ConflictAlgorithm.abort);

        await transaction.rawUpdate(
          '''
          UPDATE products
          SET stock_quantity = stock_quantity - ?
          WHERE id = ?
          ''',
          [item.quantity, item.productId],
        );

        await transaction.insert('stock_movements', {
          'id': '${sale.id}-${item.productId}',
          'product_id': item.productId,
          'movement_type': 'sale',
          'quantity': -item.quantity,
          'reference_id': sale.id,
          'created_at': sale.createdAt.toIso8601String(),
        }, conflictAlgorithm: ConflictAlgorithm.abort);
      }
    });
  }
}
