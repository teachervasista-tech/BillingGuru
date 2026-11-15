import '../../../../core/database/app_database.dart';
import '../../../../core/database/migrations.dart';
import '../../../../core/database/row_reader.dart';
import '../../../../core/period/date_range.dart';
import '../models/report_models.dart';

class ReportLocalService {
  ReportLocalService({required this.database});

  final AppDatabase database;

  Future<SalesSummary> getSalesSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database.database;

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

    final row = rows.first;

    final totalSalesCents = row.intOf('total_sales_cents');

    final totalTransactions = row.intOf('total_transactions');

    final totalItems = row.intOf('total_items');

    return SalesSummary(
      totalSalesCents: totalSalesCents,
      totalTransactions: totalTransactions,
      totalItems: totalItems,
      averageTransactionCents: totalTransactions == 0
          ? 0
          : totalSalesCents ~/ totalTransactions,
    );
  }

  Future<ProfitLoss> getProfitLoss({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database.database;
    final range = DateRange(from, to);

    final sales = (await db.rawQuery('''
      SELECT
        COALESCE(SUM(total_cents), 0) AS sales_cents,
        COALESCE(SUM(tax_cents), 0) AS tax_cents
      FROM sales
      WHERE ${DateRange.sqlClause('created_at')}
      ''', range.sqlArgs)).first;

    final cogs = (await db.rawQuery('''
      SELECT
        COALESCE(SUM(si.quantity * si.unit_cost_cents), 0) AS cogs_cents,
        COALESCE(
          SUM(CASE WHEN si.unit_cost_cents = 0 THEN si.quantity ELSE 0 END),
          0
        ) AS units_without_cost
      FROM sale_items si
      INNER JOIN sales s ON s.id = si.sale_id
      WHERE ${DateRange.sqlClause('s.created_at')}
      ''', range.sqlArgs)).first;

    final expenses = (await db.rawQuery(
      '''
      SELECT
        COALESCE(SUM(CASE WHEN category_id = ? THEN 0 ELSE amount_cents END), 0)
          AS operating_cents,
        COALESCE(SUM(CASE WHEN category_id = ? THEN amount_cents ELSE 0 END), 0)
          AS stock_cents
      FROM expenses
      WHERE ${DateRange.sqlClause('expense_date')}
      ''',
      [stockPurchaseCategoryId, stockPurchaseCategoryId, ...range.sqlArgs],
    )).first;

    return ProfitLoss(
      salesCents: sales.intOf('sales_cents'),
      taxCollectedCents: sales.intOf('tax_cents'),
      cogsCents: cogs.intOf('cogs_cents'),
      unitsWithoutCost: cogs.intOf('units_without_cost'),
      operatingExpensesCents: expenses.intOf('operating_cents'),
      stockPurchasesCents: expenses.intOf('stock_cents'),
    );
  }

  Future<List<DailySalesReport>> getDailySales({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database.database;

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

    return rows.map((row) {
      final dateText = row['sale_date'] as String;

      return DailySalesReport(
        date: DateTime.parse(dateText),
        totalCents: row.intOf('total_cents'),
        transactionCount: row.intOf('transaction_count'),
      );
    }).toList();
  }

  Future<List<PaymentMethodReport>> getPaymentMethods({
    required DateTime from,
    required DateTime to,
  }) async {
    final db = await database.database;

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
        paymentMethod: row.stringOf('payment_method'),
        totalCents: row.intOf('total_cents'),
        transactionCount: row.intOf('transaction_count'),
      );
    }).toList();
  }

  Future<List<TopProductReport>> getTopProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final db = await database.database;

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
        productId: row.stringOf('product_id'),
        productName: row.stringOf('product_name'),
        quantity: row.intOf('quantity'),
        totalCents: row.intOf('total_cents'),
      );
    }).toList();
  }

  Future<List<LowStockReport>> getLowSellingProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
  }) async {
    final db = await database.database;

    final rows = await db.rawQuery(
      '''
      SELECT
        p.id AS product_id,
        p.short_code,
        p.name AS product_name,
        COALESCE(period_sales.sold_quantity, 0) AS sold_quantity
      FROM products p
      LEFT JOIN (
        SELECT
          si.product_id,
          SUM(si.quantity) AS sold_quantity
        FROM sale_items si
        INNER JOIN sales s
          ON s.id = si.sale_id
        WHERE s.created_at >= ?
          AND s.created_at < ?
        GROUP BY si.product_id
      ) period_sales
        ON period_sales.product_id = p.id
      WHERE p.is_active = ?
      GROUP BY p.id, p.short_code, p.name, period_sales.sold_quantity
      ORDER BY sold_quantity ASC, p.name COLLATE NOCASE ASC
      LIMIT ?
      ''',
      [from.toIso8601String(), to.toIso8601String(), 1, limit],
    );

    return rows.map((row) {
      return LowStockReport(
        productId: row.stringOf('product_id'),
        shortCode: row.stringOf('short_code'),
        productName: row.stringOf('product_name'),
        soldQuantity: row.intOf('sold_quantity'),
      );
    }).toList();
  }
}
