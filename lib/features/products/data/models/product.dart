class Product {
  const Product({
    required this.id,
    required this.barcode,
    required this.name,
    required this.category,
    required this.priceCents,
    required this.taxRate,
    required this.stockQuantity,
    this.isActive = true,
  });

  final String id;
  final String barcode;
  final String name;
  final String category;
  final int priceCents;
  final int taxRate;
  final int stockQuantity;
  final bool isActive;

  Product copyWith({
    String? id,
    String? barcode,
    String? name,
    String? category,
    int? priceCents,
    int? taxRate,
    int? stockQuantity,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      priceCents: priceCents ?? this.priceCents,
      taxRate: taxRate ?? this.taxRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      isActive: isActive ?? this.isActive,
    );
  }
}
