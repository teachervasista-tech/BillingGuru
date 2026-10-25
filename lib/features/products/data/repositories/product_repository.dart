import '../models/product.dart';
import '../services/product_local_service.dart';

class ProductRepository {
  ProductRepository({required this.localService});

  final ProductLocalService localService;

  Future<List<Product>> getAllProducts() {
    return localService.getAllProducts();
  }

  Future<List<Product>> searchProducts(String query, {String? category}) {
    return localService.searchProducts(query, category: category);
  }

  Future<Product?> getProductById(String id) {
    return localService.getProductById(id);
  }

  Future<Product?> getProductByBarcode(String barcode) {
    return localService.getProductByBarcode(barcode);
  }

  Future<void> addProduct(Product product) {
    return localService.insertProduct(product);
  }

  Future<void> updateProduct(Product product) {
    return localService.updateProduct(product);
  }

  Future<void> deactivateProduct(String productId) {
    return localService.deactivateProduct(productId);
  }

  Future<List<Product>> getInactiveProducts({String search = ''}) {
    return localService.getInactiveProducts(search: search);
  }

  Future<void> activateProduct(String productId) {
    return localService.activateProduct(productId);
  }

  Future<List<String>> getActiveCategories() {
    return localService.getActiveCategories();
  }

  Future<Map<String, int>> getActiveCategoryCounts() {
    return localService.getActiveCategoryCounts();
  }

  Future<Product?> findByBarcode(String barcode) {
    return localService.findByBarcode(barcode);
  }
}
