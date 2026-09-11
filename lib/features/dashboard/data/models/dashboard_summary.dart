class DashboardSummary {
  const DashboardSummary({
    required this.todaySalesCents,
    required this.todaySalesCount,
    required this.activeProductsCount,
    required this.lowStockProductsCount,
    required this.recentSales,
  });

  final int todaySalesCents;
  final int todaySalesCount;
  final int activeProductsCount;
  final int lowStockProductsCount;
  final List<RecentSale> recentSales;
}

class RecentSale {
  const RecentSale({
    required this.invoiceNumber,
    required this.totalCents,
    required this.paymentMethod,
    required this.createdAt,
  });

  final String invoiceNumber;
  final int totalCents;
  final String paymentMethod;
  final DateTime createdAt;
}
