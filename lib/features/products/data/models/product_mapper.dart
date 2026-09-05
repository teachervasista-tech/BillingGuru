import 'product.dart';

class ProductMapper {
  static Product fromMap(Map<String, Object?> map) {
    return Product(
      id: map['id'] as String,
      barcode: map['barcode'] as String,
      name: map['name'] as String,
      priceCents: map['price_cents'] as int,
      taxRate: map['tax_rate'] as int,
      stockQuantity: map['stock_quantity'] as int,
    );
  }

  static Map<String, Object?> toMap(Product product) {
    return {
      'id': product.id,
      'barcode': product.barcode,
      'name': product.name,
      'price_cents': product.priceCents,
      'tax_rate': product.taxRate,
      'stock_quantity': product.stockQuantity,
      'is_active': 1,
    };
  }
}
