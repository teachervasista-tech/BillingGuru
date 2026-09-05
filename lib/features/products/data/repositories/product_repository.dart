import '../models/product.dart';
import '../services/product_local_service.dart';

class ProductRepository {
  ProductRepository({required this.localService});

  final ProductLocalService localService;

  Future<List<Product>> getAllProducts() => localService.getAllProducts();

  Future<List<Product>> searchProducts(String query) =>
      localService.searchProducts(query);

  Future<Product?> getProductByBarcode(String barcode) =>
      localService.getProductByBarcode(barcode);

  Future<void> addProduct(Product product) =>
      localService.insertProduct(product);
}
