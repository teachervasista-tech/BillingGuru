import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ProductImageStorage {
  ProductImageStorage._();

  static Future<String?> pickAndStoreImage({String? productId}) async {
    const imageGroup = XTypeGroup(
      label: 'Images',
      extensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp'],
    );

    final selectedFile = await openFile(acceptedTypeGroups: const [imageGroup]);

    if (selectedFile == null) {
      return null;
    }

    final bytes = await selectedFile.readAsBytes();

    final applicationDirectory = await getApplicationSupportDirectory();

    final imagesDirectory = Directory(
      path.join(applicationDirectory.path, 'product_images'),
    );

    if (!imagesDirectory.existsSync()) {
      await imagesDirectory.create(recursive: true);
    }

    final extension = path.extension(selectedFile.name).toLowerCase();

    final safeProductId =
        productId ?? DateTime.now().microsecondsSinceEpoch.toString();

    final destinationPath = path.join(
      imagesDirectory.path,
      '$safeProductId$extension',
    );

    final destinationFile = File(destinationPath);

    await destinationFile.writeAsBytes(bytes, flush: true);

    return destinationFile.path;
  }

  static Future<void> deleteImage(String? imagePath) async {
    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    final file = File(imagePath);

    if (await file.exists()) {
      await file.delete();
    }
  }
}
