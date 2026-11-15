class InventoryItem {
  const InventoryItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.stockQuantity,
    required this.priceCents,
    required this.isActive,
    this.category = 'Other',
    this.costPriceCents = 0,
  });

  final String category;
  final String productId;
  final String name;
  final String barcode;
  final int stockQuantity;
  final int priceCents;
  final bool isActive;
  final int costPriceCents;

  bool isLowStock({int threshold = 10}) {
    return stockQuantity <= threshold;
  }
}
