import '../models/product.dart';
import '../services/product_local_service.dart';

class ProductRepository {
  ProductRepository({required this.localService});

  final ProductLocalService localService;

  Future<List<Product>> getAllProducts() {
    return localService.getAllProducts();
  }

  Future<List<Product>> searchProducts(String query) {
    return localService.searchProducts(query);
  }

  Future<Product?> getProductByBarcode(String barcode) {
    return localService.getProductByBarcode(barcode);
  }

  Future<void> addProduct(Product product) {
    return localService.insertProduct(product);
  }
}
