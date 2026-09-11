//import 'package:sqflite/sqflite.dart';

import '../../../../core/database/app_database.dart';
import '../models/dashboard_summary.dart';

class DashboardLocalService {
  DashboardLocalService({required this.database});

  final AppDatabase database;

  Future<DashboardSummary> getSummary({int lowStockThreshold = 10}) async {
    final db = await database.database;

    final todayStart = _todayStart().toIso8601String();
    final tomorrowStart = _tomorrowStart().toIso8601String();

    final salesTotals = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS sales_count,
        COALESCE(SUM(total_cents), 0) AS sales_total
      FROM sales
      WHERE created_at >= ?
        AND created_at < ?
      ''',
      [todayStart, tomorrowStart],
    );

    final productTotals = await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS active_products,
        COALESCE(
          SUM(
            CASE
              WHEN stock_quantity <= ? THEN 1
              ELSE 0
            END
          ),
          0
        ) AS low_stock_products
      FROM products
      WHERE is_active = 1
      ''',
      [lowStockThreshold],
    );

    final recentSaleRows = await db.query(
      'sales',
      orderBy: 'created_at DESC',
      limit: 5,
    );

    final salesRow = salesTotals.first;
    final productsRow = productTotals.first;

    return DashboardSummary(
      todaySalesCents: _asInt(salesRow['sales_total']),
      todaySalesCount: _asInt(salesRow['sales_count']),
      activeProductsCount: _asInt(productsRow['active_products']),
      lowStockProductsCount: _asInt(productsRow['low_stock_products']),
      recentSales: recentSaleRows.map(_recentSaleFromMap).toList(),
    );
  }

  RecentSale _recentSaleFromMap(Map<String, Object?> map) {
    return RecentSale(
      invoiceNumber: map['invoice_number'] as String,
      totalCents: _asInt(map['total_cents']),
      paymentMethod: map['payment_method'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  int _asInt(Object? value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse('$value') ?? 0;
  }

  DateTime _todayStart() {
    final now = DateTime.now();

    return DateTime(now.year, now.month, now.day);
  }

  DateTime _tomorrowStart() {
    return _todayStart().add(const Duration(days: 1));
  }
}
