//import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/sale_summary.dart';

class SalesLocalService {
  SalesLocalService({required this.database});

  final AppDatabase database;

  Future<List<SaleSummary>> getSales({String search = ''}) async {
    final db = await database.database;
    final trimmedSearch = search.trim();

    final rows = await db.query(
      'sales',
      where: trimmedSearch.isEmpty ? null : 'invoice_number LIKE ?',
      whereArgs: trimmedSearch.isEmpty ? null : ['%$trimmedSearch%'],
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
