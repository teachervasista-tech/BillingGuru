class SaleItem {
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPriceCents,
    required this.totalCents,
    this.productName,
  });

  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final int unitPriceCents;
  final int totalCents;
  final String? productName;
}
