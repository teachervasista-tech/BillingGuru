import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

/// Copies user-picked files into the app support directory so they survive
/// the original being moved. Folders under [root] are included in backups.
class AppFileStorage {
  AppFileStorage._();

  static const productImagesFolder = 'product_images';
  static const expenseAttachmentsFolder = 'expense_attachments';

  /// Folders that belong in a backup.
  static const backupFolders = [productImagesFolder, expenseAttachmentsFolder];

  static const imageExtensions = ['jpg', 'jpeg', 'png', 'webp', 'bmp'];
  static const attachmentExtensions = [...imageExtensions, 'pdf'];

  static Future<Directory> root() => getApplicationSupportDirectory();

  static Future<Directory> folder(String name) async {
    final directory = Directory(path.join((await root()).path, name));
    if (!directory.existsSync()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// Opens a file picker and copies the chosen file into [folderName].
  /// Returns the stored path, or null when the user cancels.
  static Future<String?> pickAndStore({
    required String folderName,
    required String label,
    required List<String> extensions,
    String? fileName,
  }) async {
    final selected = await openFile(
      acceptedTypeGroups: [XTypeGroup(label: label, extensions: extensions)],
    );
    if (selected == null) return null;

    final directory = await folder(folderName);
    final extension = path.extension(selected.name).toLowerCase();
    final baseName =
        fileName ?? DateTime.now().microsecondsSinceEpoch.toString();
    final destination = File(path.join(directory.path, '$baseName$extension'));
    await destination.writeAsBytes(await selected.readAsBytes(), flush: true);
    return destination.path;
  }

  static Future<void> delete(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }
}
