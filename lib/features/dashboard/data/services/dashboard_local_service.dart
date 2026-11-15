import '../../../../core/database/app_database.dart';
import '../../../../core/database/row_reader.dart';
import '../../../../core/period/date_range.dart';
import '../models/dashboard_summary.dart';

class DashboardLocalService {
  DashboardLocalService({required this.database});

  final AppDatabase database;

  Future<DashboardSummary> getSummary({int lowStockThreshold = 10}) async {
    final db = await database.database;

    final today = PeriodPreset.today.rangeFor(DateTime.now())!;

    final salesTotals = await db.rawQuery('''
      SELECT
        COUNT(*) AS sales_count,
        COALESCE(SUM(total_cents), 0) AS sales_total
      FROM effective_sales
      WHERE ${DateRange.sqlClause('created_at')}
      ''', today.sqlArgs);

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
      todaySalesCents: salesRow.intOf('sales_total'),
      todaySalesCount: salesRow.intOf('sales_count'),
      activeProductsCount: productsRow.intOf('active_products'),
      lowStockProductsCount: productsRow.intOf('low_stock_products'),
      recentSales: recentSaleRows.map(_recentSaleFromMap).toList(),
    );
  }

  RecentSale _recentSaleFromMap(Map<String, Object?> map) {
    return RecentSale(
      invoiceNumber: map['invoice_number'] as String,
      totalCents: map.intOf('total_cents'),
      paymentMethod: map['payment_method'] as String,
      createdAt: map.dateOf('created_at'),
    );
  }
}
