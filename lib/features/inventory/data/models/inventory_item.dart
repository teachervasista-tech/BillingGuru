class InventoryItem {
  const InventoryItem({
    required this.productId,
    required this.name,
    required this.barcode,
    required this.stockQuantity,
    required this.priceCents,
    required this.isActive,
  });

  final String productId;
  final String name;
  final String barcode;
  final int stockQuantity;
  final int priceCents;
  final bool isActive;

  bool isLowStock({int threshold = 10}) {
    return stockQuantity <= threshold;
  }
}
