class Product {
  final String id;
  final String barcode;
  final String name;
  final int priceCents;
  final int taxRate;
  final int stockQuantity;

  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.priceCents,
    required this.taxRate,
    required this.stockQuantity,
  });

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    int? priceCents,
    int? taxRate,
    int? stockQuantity,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      priceCents: priceCents ?? this.priceCents,
      taxRate: taxRate ?? this.taxRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
    );
  }
}
