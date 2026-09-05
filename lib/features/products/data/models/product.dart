class Product {
  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.priceCents,
    required this.taxRate,
    required this.stockQuantity,
  });

  final String id;
  final String barcode;
  final String name;
  final int priceCents;
  final int taxRate;
  final int stockQuantity;
}
