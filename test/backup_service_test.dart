import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:billing_guru/core/backup/backup_service.dart';
import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/storage/app_file_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory temp;
  late Directory filesRoot;
  late AppDatabase database;
  late BackupService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app_default_tax_rate': 7,
      'receipt_template': 'detailed',
    });
    temp = await Directory.systemTemp.createTemp('bg_backup_test_');
    filesRoot = Directory(p.join(temp.path, 'support'))..createSync();
    database = AppDatabase.forTesting(
      databaseFactoryFfiNoIsolate,
      p.join(temp.path, 'pos_billing.db'),
    );
    service = BackupService(
      database: database,
      filesRoot: () async => filesRoot,
    );
  });

  tearDown(() async {
    await database.close();
    await temp.delete(recursive: true);
  });

  Future<String> writeAttachment(
    String folder,
    String name,
    String text,
  ) async {
    final dir = Directory(p.join(filesRoot.path, folder))
      ..createSync(recursive: true);
    final file = File(p.join(dir.path, name))..writeAsStringSync(text);
    return file.path;
  }

  test(
    'backup round-trip restores data, files, paths and preferences',
    () async {
      final db = await database.database;
      // Paths as written on another machine (Windows-style).
      await writeAttachment(
        AppFileStorage.productImagesFolder,
        'p1.png',
        'img',
      );
      await writeAttachment(
        AppFileStorage.expenseAttachmentsFolder,
        'bill.pdf',
        'pdf',
      );
      await db.update('products', {
        'image_path': r'C:\Users\old\AppData\product_images\p1.png',
      }, where: "id = 'Test-001'");
      await db.insert('expenses', {
        'id': 'e1',
        'category_id': 'cat-rent',
        'amount_cents': 1000,
        'payment_method': 'cash',
        'attachment_path': r'C:\Users\old\AppData\expense_attachments\bill.pdf',
        'expense_date': DateTime(2026, 11, 1).toIso8601String(),
        'created_at': DateTime(2026, 11, 1).toIso8601String(),
      });

      final bytes = await service.createArchive(now: DateTime(2026, 11, 15));
      expect(service.inspect(bytes).createdAt, DateTime(2026, 11, 15));

      // Diverge from the backup: delete data and files, change preferences.
      await db.delete('expenses');
      await db.delete('products', where: "id = 'Test-001'");
      await Directory(
        p.join(filesRoot.path, AppFileStorage.productImagesFolder),
      ).delete(recursive: true);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('app_default_tax_rate', 25);

      await service.restoreArchive(bytes);

      final restored = await database.database;
      final product = (await restored.query(
        'products',
        where: "id = 'Test-001'",
      )).single;
      final imagePath = product['image_path'] as String;
      expect(
        imagePath,
        p.join(filesRoot.path, AppFileStorage.productImagesFolder, 'p1.png'),
      );
      expect(File(imagePath).readAsStringSync(), 'img');

      final expense = (await restored.query('expenses')).single;
      expect(
        File(expense['attachment_path'] as String).readAsStringSync(),
        'pdf',
      );
      expect(prefs.getInt('app_default_tax_rate'), 7);
      expect(prefs.getString('receipt_template'), 'detailed');
    },
  );

  test('rejects files that are not Billing Guru backups', () async {
    await database.database;
    expect(
      () => service.restoreArchive(Uint8List.fromList([1, 2, 3])),
      throwsA(isA<BackupException>()),
    );

    final foreign = Archive()
      ..addFile(ArchiveFile.bytes('readme.txt', utf8.encode('hi')));
    expect(
      () => service.restoreArchive(
        Uint8List.fromList(ZipEncoder().encode(foreign)),
      ),
      throwsA(isA<BackupException>()),
    );
  });

  test('rejects backups from a newer schema version', () async {
    await database.database;
    final newer = Archive()
      ..addFile(
        ArchiveFile.bytes(
          BackupService.manifestFile,
          utf8.encode(
            jsonEncode({
              'app': 'Billing Guru',
              'appVersion': '99.0.0',
              'schemaVersion': 999,
              'createdAt': '2030-01-01T00:00:00.000',
            }),
          ),
        ),
      );
    await expectLater(
      service.restoreArchive(Uint8List.fromList(ZipEncoder().encode(newer))),
      throwsA(
        isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('newer version'),
        ),
      ),
    );
  });
}
