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
    required this.stockQuantity,
  });

  final String productId;
  final String shortCode;
  final String productName;
  final int stockQuantity;
}
