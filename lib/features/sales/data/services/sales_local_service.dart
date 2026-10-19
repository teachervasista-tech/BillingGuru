//import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../../../checkout/domain/sale_item.dart';
import '../../domain/sales_period.dart';
import '../models/sale_summary.dart';

class SalesLocalService {
  SalesLocalService({required this.database});

  final AppDatabase database;

  Future<List<SaleSummary>> getSales({
    String search = '',
    SalesDateRange? range,
  }) async {
    final db = await database.database;
    final trimmedSearch = search.trim();

    final conditions = <String>[];
    final arguments = <Object?>[];
    if (trimmedSearch.isNotEmpty) {
      conditions.add('invoice_number LIKE ?');
      arguments.add('%$trimmedSearch%');
    }
    // created_at is stored as a local ISO-8601 string, which sorts correctly.
    if (range != null) {
      conditions.add('created_at >= ? AND created_at < ?');
      arguments.add(range.from.toIso8601String());
      arguments.add(range.to.toIso8601String());
    }

    final rows = await db.query(
      'sales',
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : arguments,
      orderBy: 'created_at DESC',
    );

    return rows.map(_fromMap).toList();
  }

  Future<SaleSummary?> getSaleById(String saleId) async {
    final db = await database.database;

    final rows = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );

    if (rows.isEmpty) {
      return null;
    }

    return _fromMap(rows.first);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final db = await database.database;

    final rows = await db.rawQuery(
      '''
      SELECT si.id, si.sale_id, si.product_id, si.quantity,
             si.unit_price_cents, si.total_cents, p.name AS product_name
      FROM sale_items si
      LEFT JOIN products p ON p.id = si.product_id
      WHERE si.sale_id = ?
      ORDER BY si.rowid ASC
      ''',
      [saleId],
    );

    return rows
        .map(
          (map) => SaleItem(
            id: map['id'] as String,
            saleId: map['sale_id'] as String,
            productId: map['product_id'] as String,
            quantity: map['quantity'] as int,
            unitPriceCents: map['unit_price_cents'] as int,
            totalCents: map['total_cents'] as int,
            productName: map['product_name'] as String?,
          ),
        )
        .toList();
  }

  SaleSummary _fromMap(Map<String, Object?> map) {
    return SaleSummary(
      id: map['id'] as String,
      invoiceNumber: map['invoice_number'] as String,
      subtotalCents: map['subtotal_cents'] as int,
      discountCents: map['discount_cents'] as int,
      taxCents: map['tax_cents'] as int,
      totalCents: map['total_cents'] as int,
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      syncStatus: map['sync_status'] as String,
    );
  }
}
