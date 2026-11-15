import 'app_file_storage.dart';

class ProductImageStorage {
  ProductImageStorage._();

  static Future<String?> pickAndStoreImage({String? productId}) {
    return AppFileStorage.pickAndStore(
      folderName: AppFileStorage.productImagesFolder,
      label: 'Images',
      extensions: AppFileStorage.imageExtensions,
      fileName: productId,
    );
  }

  static Future<void> deleteImage(String? imagePath) =>
      AppFileStorage.delete(imagePath);
}
