class SaleItem {
  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.quantity,
    required this.unitPriceCents,
    required this.totalCents,
    this.productName,
    this.unitCostCents = 0,
    this.returnedQuantity = 0,
  });

  final String id;
  final String saleId;
  final String productId;
  final int quantity;
  final int unitPriceCents;
  final int totalCents;
  final String? productName;

  /// Product cost at the time of sale (snapshot for COGS).
  final int unitCostCents;

  int get totalCostCents => unitCostCents * quantity;

  /// Units already returned by the customer.
  final int returnedQuantity;

  int get returnableQuantity => quantity - returnedQuantity;
}
