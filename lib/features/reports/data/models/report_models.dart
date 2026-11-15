class SalesSummary {
  const SalesSummary({
    required this.totalSalesCents,
    required this.totalTransactions,
    required this.totalItems,
    required this.averageTransactionCents,
  });

  final int totalSalesCents;
  final int totalTransactions;
  final int totalItems;
  final int averageTransactionCents;

  const SalesSummary.empty()
    : totalSalesCents = 0,
      totalTransactions = 0,
      totalItems = 0,
      averageTransactionCents = 0;
}

class DailySalesReport {
  const DailySalesReport({
    required this.date,
    required this.totalCents,
    required this.transactionCount,
  });

  final DateTime date;
  final int totalCents;
  final int transactionCount;
}

class PaymentMethodReport {
  const PaymentMethodReport({
    required this.paymentMethod,
    required this.totalCents,
    required this.transactionCount,
  });

  final String paymentMethod;
  final int totalCents;
  final int transactionCount;
}

class TopProductReport {
  const TopProductReport({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalCents,
  });

  final String productId;
  final String productName;
  final int quantity;
  final int totalCents;
}

class LowStockReport {
  const LowStockReport({
    required this.productId,
    required this.shortCode,
    required this.productName,
    required this.soldQuantity,
  });

  final String productId;
  final String shortCode;
  final String productName;
  final int soldQuantity;
}

/// Profit & loss for a period.
///
/// Stock purchases are inventory, not operating expense: their cost reaches
/// profit through COGS when the goods are sold, so they are reported
/// separately (cash out) and excluded from [netProfitCents].
class ProfitLoss {
  const ProfitLoss({
    required this.salesCents,
    required this.taxCollectedCents,
    required this.cogsCents,
    required this.operatingExpensesCents,
    required this.stockPurchasesCents,
    required this.unitsWithoutCost,
  });

  const ProfitLoss.empty()
    : salesCents = 0,
      taxCollectedCents = 0,
      cogsCents = 0,
      operatingExpensesCents = 0,
      stockPurchasesCents = 0,
      unitsWithoutCost = 0;

  /// Sales total including tax.
  final int salesCents;
  final int taxCollectedCents;

  /// Cost of goods sold (quantity x cost price at time of sale).
  final int cogsCents;
  final int operatingExpensesCents;
  final int stockPurchasesCents;

  /// Units sold whose product had no cost price; COGS is understated.
  final int unitsWithoutCost;

  int get netSalesCents => salesCents - taxCollectedCents;
  int get grossProfitCents => netSalesCents - cogsCents;
  int get netProfitCents => grossProfitCents - operatingExpensesCents;

  /// Money in minus all money out (incl. stock purchases).
  int get cashFlowCents =>
      salesCents - operatingExpensesCents - stockPurchasesCents;

  double get grossMargin =>
      netSalesCents == 0 ? 0 : grossProfitCents / netSalesCents;
  double get netMargin =>
      netSalesCents == 0 ? 0 : netProfitCents / netSalesCents;
}
