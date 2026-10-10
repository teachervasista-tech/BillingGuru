import '../../../../core/database/app_database.dart';
import '../models/report_models.dart';

class ReportLocalService {
  ReportLocalService({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<SalesSummary> getSalesSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    //debugPrint('[Reports] Loading sales summary');
    final db = await _database.database;

    final rows = await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(total_cents), 0) AS total_sales_cents,
        COUNT(*) AS total_transactions,
        COALESCE(
          (
            SELECT SUM(quantity)
            FROM sale_items
            WHERE sale_id IN (
              SELECT id
              FROM sales
              WHERE created_at >= ?
                AND created_at < ?
            )
          ),
          0
        ) AS total_items
      FROM sales
      WHERE created_at >= ?
        AND created_at < ?
      ''',
      [
        from.toIso8601String(),
        to.toIso8601String(),
        from.toIso8601String(),
        to.toIso8601String(),
      ],
    );

    //debugPrint('[Reports] Sales summary loaded');

    final row = rows.first;

    final totalSalesCents = (row['total_sales_cents'] as num?)?.toInt() ?? 0;

    final totalTransactions = (row['total_transactions'] as num?)?.toInt() ?? 0;

    final totalItems = (row['total_items'] as num?)?.toInt() ?? 0;

    return SalesSummary(
      totalSalesCents: totalSalesCents,
      totalTransactions: totalTransactions,
      totalItems: totalItems,
      averageTransactionCents: totalTransactions == 0
          ? 0
          : totalSalesCents ~/ totalTransactions,
    );
  }

  Future<List<DailySalesReport>> getDailySales({
    required DateTime from,
    required DateTime to,
  }) async {
    //debugPrint('[Reports] Loading daily sales');
    final db = await _database.database;

    final rows = await db.rawQuery(
      '''
      SELECT
        substr(created_at, 1, 10) AS sale_date,
        COALESCE(SUM(total_cents), 0) AS total_cents,
        COUNT(*) AS transaction_count
      FROM sales
      WHERE created_at >= ?
        AND created_at < ?
      GROUP BY substr(created_at, 1, 10)
      ORDER BY sale_date ASC
      ''',
      [from.toIso8601String(), to.toIso8601String()],
    );
    //debugPrint('[Reports] Daily sales loaded: ${rows.length}');

    return rows.map((row) {
      final dateText = row['sale_date'] as String;

      return DailySalesReport(
        date: DateTime.parse(dateText),
        totalCents: (row['total_cents'] as num?)?.toInt() ?? 0,
        transactionCount: (row['transaction_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<PaymentMethodReport>> getPaymentMethods({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await _database.database;

    final rows = await db.rawQuery(
      '''
      SELECT
        payment_method,
        COALESCE(SUM(total_cents), 0) AS total_cents,
        COUNT(*) AS transaction_count
      FROM sales
      WHERE created_at >= ?
        AND created_at < ?
      GROUP BY payment_method
      ORDER BY total_cents DESC
      ''',
      [from.toIso8601String(), to.toIso8601String()],
    );

    return rows.map((row) {
      return PaymentMethodReport(
        paymentMethod: row['payment_method'] as String,
        totalCents: (row['total_cents'] as num?)?.toInt() ?? 0,
        transactionCount: (row['transaction_count'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<TopProductReport>> getTopProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final db = await _database.database;

    final rows = await db.rawQuery(
      '''
      SELECT
        p.id AS product_id,
        p.name AS product_name,
        COALESCE(SUM(si.quantity), 0) AS quantity,
        COALESCE(SUM(si.total_cents), 0) AS total_cents
      FROM sale_items si
      INNER JOIN sales s
        ON s.id = si.sale_id
      INNER JOIN products p
        ON p.id = si.product_id
      WHERE s.created_at >= ?
        AND s.created_at < ?
      GROUP BY p.id, p.name
      ORDER BY quantity DESC
      LIMIT ?
      ''',
      [from.toIso8601String(), to.toIso8601String(), limit],
    );

    return rows.map((row) {
      return TopProductReport(
        productId: row['product_id'] as String,
        productName: row['product_name'] as String,
        quantity: (row['quantity'] as num?)?.toInt() ?? 0,
        totalCents: (row['total_cents'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  Future<List<LowStockReport>> getLowStockProducts({int threshold = 10}) async {
    final db = await _database.database;

    final rows = await db.query(
      'products',
      columns: ['id', 'short_code', 'name', 'stock_quantity'],
      where: '''
        is_active = ?
        AND stock_quantity <= ?
      ''',
      whereArgs: [1, threshold],
      orderBy: 'stock_quantity ASC, name COLLATE NOCASE ASC',
    );

    return rows.map((row) {
      return LowStockReport(
        productId: row['id'] as String,
        shortCode: row['short_code'] as String,
        productName: row['name'] as String,
        stockQuantity: row['stock_quantity'] as int,
      );
    }).toList();
  }
}
