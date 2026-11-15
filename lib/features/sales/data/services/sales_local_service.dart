import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/row_reader.dart';
import '../../../checkout/domain/sale_item.dart';
import '../../domain/sales_period.dart';
import '../models/sale_summary.dart';

class SalesLocalService {
  SalesLocalService({required this.database});

  final AppDatabase database;
  static const _uuid = Uuid();

  static const _selectSales = '''
    SELECT s.*, c.name AS customer_name
    FROM sales s
    LEFT JOIN customers c ON c.id = s.customer_id
  ''';

  Future<List<SaleSummary>> getSales({
    String search = '',
    SalesDateRange? range,
    String? customerId,
  }) async {
    final db = await database.database;
    final trimmedSearch = search.trim();

    final conditions = <String>[];
    final arguments = <Object?>[];
    if (trimmedSearch.isNotEmpty) {
      conditions.add('(s.invoice_number LIKE ? OR c.name LIKE ?)');
      arguments.addAll(['%$trimmedSearch%', '%$trimmedSearch%']);
    }
    // created_at is stored as a local ISO-8601 string, which sorts correctly.
    if (range != null) {
      conditions.add(DateRange.sqlClause('s.created_at'));
      arguments.addAll(range.sqlArgs);
    }
    if (customerId != null) {
      conditions.add('s.customer_id = ?');
      arguments.add(customerId);
    }

    final rows = await db.rawQuery('''
      $_selectSales
      ${conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}'}
      ORDER BY s.created_at DESC
      ''', arguments);

    return rows.map(_fromMap).toList();
  }

  Future<SaleSummary?> getSaleById(String saleId) async {
    final db = await database.database;

    final rows = await db.rawQuery('$_selectSales WHERE s.id = ? LIMIT 1', [
      saleId,
    ]);

    return rows.isEmpty ? null : _fromMap(rows.first);
  }

  Future<List<SaleItem>> getSaleItems(String saleId) async {
    final db = await database.database;

    final rows = await db.rawQuery(
      '''
      SELECT si.*, p.name AS product_name
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
            id: map.stringOf('id'),
            saleId: map.stringOf('sale_id'),
            productId: map.stringOf('product_id'),
            quantity: map.intOf('quantity'),
            unitPriceCents: map.intOf('unit_price_cents'),
            totalCents: map.intOf('total_cents'),
            productName: map.stringOrNull('product_name'),
            unitCostCents: map.intOf('unit_cost_cents'),
            returnedQuantity: map.intOf('returned_quantity'),
          ),
        )
        .toList();
  }

  /// Cancels the whole sale: restocks every unit not yet returned and
  /// refunds the remaining amount.
  Future<void> voidSale(String saleId, {String? reason}) async {
    final db = await database.database;
    await db.transaction((txn) async {
      final sale = await _openSale(txn, saleId);
      final items = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      final returns = {
        for (final item in items)
          if (item.intOf('quantity') > item.intOf('returned_quantity'))
            item.stringOf('id'):
                item.intOf('quantity') - item.intOf('returned_quantity'),
      };
      await _applyReturn(
        txn,
        sale: sale,
        items: items,
        quantities: returns,
        kind: 'void',
        reason: reason,
        forceFull: true,
      );
    });
  }

  /// Returns [quantities] (sale item id -> units) and refunds them,
  /// including their share of the sale's tax.
  Future<void> returnItems(
    String saleId,
    Map<String, int> quantities, {
    String? reason,
  }) async {
    final requested = {
      for (final e in quantities.entries)
        if (e.value > 0) e.key: e.value,
    };
    if (requested.isEmpty) {
      throw ArgumentError('Choose at least one item to return.');
    }
    final db = await database.database;
    await db.transaction((txn) async {
      final sale = await _openSale(txn, saleId);
      final items = await txn.query(
        'sale_items',
        where: 'sale_id = ?',
        whereArgs: [saleId],
      );
      await _applyReturn(
        txn,
        sale: sale,
        items: items,
        quantities: requested,
        kind: 'return',
        reason: reason,
      );
    });
  }

  Future<Map<String, Object?>> _openSale(Transaction txn, String saleId) async {
    final rows = await txn.query(
      'sales',
      where: 'id = ?',
      whereArgs: [saleId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Sale not found.');
    final status = SaleStatus.parse(rows.first.stringOf('status'));
    if (!status.isOpen) {
      throw StateError('This sale is already ${status.label.toLowerCase()}.');
    }
    return rows.first;
  }

  Future<void> _applyReturn(
    Transaction txn, {
    required Map<String, Object?> sale,
    required List<Map<String, Object?>> items,
    required Map<String, int> quantities,
    required String kind,
    String? reason,
    bool forceFull = false,
  }) async {
    final saleId = sale.stringOf('id');
    final returnId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    final byId = {for (final item in items) item.stringOf('id'): item};

    var refundSubtotal = 0;
    final lines = <({Map<String, Object?> item, int qty, int refund})>[];
    for (final entry in quantities.entries) {
      final item = byId[entry.key];
      if (item == null) throw StateError('Item is not part of this sale.');
      final available =
          item.intOf('quantity') - item.intOf('returned_quantity');
      if (entry.value > available) {
        throw StateError('Only $available unit(s) can be returned.');
      }
      final refund = entry.value * item.intOf('unit_price_cents');
      refundSubtotal += refund;
      lines.add((item: item, qty: entry.value, refund: refund));
    }

    final allReturned = items.every((item) {
      final already = item.intOf('returned_quantity');
      final now = quantities[item.stringOf('id')] ?? 0;
      return already + now >= item.intOf('quantity');
    });

    final saleTax = sale.intOf('tax_cents');
    final saleSubtotal = sale.intOf('subtotal_cents');
    final refundedSoFar = sale.intOf('refunded_cents');
    final refundedTaxSoFar = sale.intOf('refunded_tax_cents');

    int refundTax;
    int refundTotal;
    if (allReturned || forceFull) {
      // Settle exactly to the sale total to avoid rounding remainders.
      refundTax = saleTax - refundedTaxSoFar;
      refundTotal = sale.intOf('total_cents') - refundedSoFar;
    } else {
      refundTax = saleSubtotal == 0
          ? 0
          : (refundSubtotal * saleTax / saleSubtotal).round();
      refundTotal = refundSubtotal + refundTax;
    }

    await txn.insert('sale_returns', {
      'id': returnId,
      'sale_id': saleId,
      'kind': kind,
      'reason': (reason?.trim().isEmpty ?? true) ? null : reason!.trim(),
      'refund_cents': refundTotal,
      'refund_tax_cents': refundTax,
      'created_at': now,
    });

    for (final line in lines) {
      final itemId = line.item.stringOf('id');
      final productId = line.item.stringOf('product_id');
      await txn.insert('sale_return_items', {
        'id': _uuid.v4(),
        'return_id': returnId,
        'sale_item_id': itemId,
        'product_id': productId,
        'quantity': line.qty,
        'refund_cents': line.refund,
      });
      await txn.rawUpdate(
        'UPDATE sale_items SET returned_quantity = returned_quantity + ? '
        'WHERE id = ?',
        [line.qty, itemId],
      );
      await txn.rawUpdate(
        'UPDATE products SET stock_quantity = stock_quantity + ? WHERE id = ?',
        [line.qty, productId],
      );
      await txn.insert('stock_movements', {
        'id': '$returnId-$itemId',
        'product_id': productId,
        'movement_type': kind,
        'quantity': line.qty,
        'reference_id': returnId,
        'created_at': now,
      });
    }

    final status = kind == 'void'
        ? SaleStatus.voided
        : allReturned
        ? SaleStatus.refunded
        : SaleStatus.partiallyRefunded;
    await txn.update(
      'sales',
      {
        'status': status.dbValue,
        'refunded_cents': refundedSoFar + refundTotal,
        'refunded_tax_cents': refundedTaxSoFar + refundTax,
      },
      where: 'id = ?',
      whereArgs: [saleId],
    );
  }

  SaleSummary _fromMap(Map<String, Object?> map) {
    return SaleSummary(
      id: map.stringOf('id'),
      invoiceNumber: map.stringOf('invoice_number'),
      subtotalCents: map.intOf('subtotal_cents'),
      discountCents: map.intOf('discount_cents'),
      taxCents: map.intOf('tax_cents'),
      totalCents: map.intOf('total_cents'),
      paymentMethod: map.stringOf('payment_method'),
      createdAt: map.dateOf('created_at'),
      syncStatus: map.stringOf('sync_status'),
      status: SaleStatus.parse(map.stringOrNull('status')),
      refundedCents: map.intOf('refunded_cents'),
      customerId: map.stringOrNull('customer_id'),
      customerName: map.stringOrNull('customer_name'),
    );
  }
}
