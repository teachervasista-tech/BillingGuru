class Product {
  const Product({
    required this.id,
    required this.shortCode,
    required this.barcode,
    required this.name,
    required this.category,
    required this.priceCents,
    required this.taxRate,
    required this.stockQuantity,
    this.imagePath,
    this.isActive = true,
  });

  final String id;
  final String shortCode;
  final String barcode;
  final String name;
  final String category;
  final int priceCents;
  final int taxRate;
  final int stockQuantity;
  final String? imagePath;
  final bool isActive;

  Product copyWith({
    String? id,
    String? shortCode,
    String? barcode,
    String? name,
    String? category,
    int? priceCents,
    int? taxRate,
    int? stockQuantity,
    String? imagePath,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      shortCode: shortCode ?? this.shortCode,
      barcode: barcode ?? this.barcode,
      name: name ?? this.name,
      category: category ?? this.category,
      priceCents: priceCents ?? this.priceCents,
      taxRate: taxRate ?? this.taxRate,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      imagePath: imagePath ?? this.imagePath,
      isActive: isActive ?? this.isActive,
    );
  }
}
