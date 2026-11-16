import 'dart:io';

import 'package:billing_guru/core/backup/auto_backup_service.dart';
import 'package:billing_guru/core/backup/backup_service.dart';
import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/database/database_initializer_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory temp;
  late Directory local;
  late AppDatabase database;
  late AutoBackupService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    temp = await Directory.systemTemp.createTemp('bg_auto_backup_test_');
    local = Directory(p.join(temp.path, 'local'))..createSync();
    final support = Directory(p.join(temp.path, 'support'))..createSync();
    database = AppDatabase.forTesting(
      databaseFactoryFfiNoIsolate,
      p.join(temp.path, 'pos_billing.db'),
    );
    service = AutoBackupService(
      backup: BackupService(database: database, filesRoot: () async => support),
      defaultFolder: () async => local,
      keep: 3,
    );
  });

  tearDown(() async {
    await database.close();
    await temp.delete(recursive: true);
  });

  List<String> backupsIn(Directory dir) =>
      dir.listSync().map((e) => p.basename(e.path)).toList()..sort();

  test('writes one restorable file per day to the local folder', () async {
    final status = await service.run(now: DateTime(2026, 11, 16, 9));

    expect(backupsIn(local), ['billing-guru-auto-2026-11-16.zip']);
    expect(status.lastAt, DateTime(2026, 11, 16, 9));
    expect(status.lastError, isNull);

    final bytes = await File(status.lastPath!).readAsBytes();
    expect(service.backup.inspect(bytes).schemaVersion, greaterThan(0));

    // A later run the same day (e.g. on close) replaces that day's file.
    await service.run(now: DateTime(2026, 11, 16, 20));
    expect(backupsIn(local), ['billing-guru-auto-2026-11-16.zip']);
  });

  test('runIfDue skips when today already has a backup', () async {
    await service.runIfDue(now: DateTime(2026, 11, 16, 9));
    final file = File(p.join(local.path, 'billing-guru-auto-2026-11-16.zip'));
    final modified = file.lastModifiedSync();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    await service.runIfDue(now: DateTime(2026, 11, 16, 15));
    expect(file.lastModifiedSync(), modified);

    await service.runIfDue(now: DateTime(2026, 11, 17, 8));
    expect(backupsIn(local), hasLength(2));
  });

  test('keeps only the newest backups', () async {
    for (var day = 1; day <= 5; day++) {
      await service.run(now: DateTime(2026, 11, day));
    }
    expect(backupsIn(local), [
      'billing-guru-auto-2026-11-03.zip',
      'billing-guru-auto-2026-11-04.zip',
      'billing-guru-auto-2026-11-05.zip',
    ]);
  });

  test('uses the chosen folder', () async {
    final usb = Directory(p.join(temp.path, 'usb'))..createSync();
    await service.setFolder(usb.path);

    final status = await service.run(now: DateTime(2026, 11, 16));
    expect(status.folder, usb.path);
    expect(backupsIn(usb), ['billing-guru-auto-2026-11-16.zip']);
    expect(backupsIn(local), isEmpty);
  });

  test(
    'falls back to this computer when the chosen folder is missing',
    () async {
      await service.setFolder(p.join(temp.path, 'unplugged-usb'));

      final status = await service.run(now: DateTime(2026, 11, 16));
      expect(backupsIn(local), ['billing-guru-auto-2026-11-16.zip']);
      expect(status.lastError, contains('was not available'));

      // Once the folder is back, the warning clears.
      Directory(p.join(temp.path, 'unplugged-usb')).createSync();
      final next = await service.run(now: DateTime(2026, 11, 17));
      expect(next.lastError, isNull);
    },
  );

  test('concurrent runs do not collide', () async {
    final results = await Future.wait([
      service.run(now: DateTime(2026, 11, 16, 9)),
      service.run(now: DateTime(2026, 11, 16, 9, 1)),
    ]);
    expect(results.every((s) => s.lastError == null), isTrue);
    expect(backupsIn(local), ['billing-guru-auto-2026-11-16.zip']);
  });

  group('legacy database location', () {
    test('copies the newest legacy database when none exists yet', () async {
      final older = Directory(p.join(temp.path, 'old-a'))..createSync();
      final newer = Directory(p.join(temp.path, 'old-b'))..createSync();
      File(p.join(older.path, AppDatabase.databaseName))
        ..writeAsStringSync('old')
        ..setLastModifiedSync(DateTime(2026, 1, 1));
      File(p.join(newer.path, AppDatabase.databaseName))
        ..writeAsStringSync('new')
        ..setLastModifiedSync(DateTime(2026, 6, 1));
      File(p.join(newer.path, '${AppDatabase.databaseName}-wal'))
          .writeAsStringSync('wal');
      final target = p.join(temp.path, 'appdata', 'database');

      final moved = await moveLegacyDatabase(
        targetDirectory: target,
        legacyDirectories: [older.path, newer.path],
      );

      expect(moved, p.join(newer.path, AppDatabase.databaseName));
      expect(
        File(p.join(target, AppDatabase.databaseName)).readAsStringSync(),
        'new',
      );
      expect(
        File(p.join(target, '${AppDatabase.databaseName}-wal')).existsSync(),
        isTrue,
      );
      // The legacy copy stays as a safety net.
      expect(
        File(p.join(newer.path, AppDatabase.databaseName)).existsSync(),
        isTrue,
      );
    });

    test('never overwrites an existing database', () async {
      final legacy = Directory(p.join(temp.path, 'old'))..createSync();
      File(p.join(legacy.path, AppDatabase.databaseName))
          .writeAsStringSync('legacy');
      final target = Directory(p.join(temp.path, 'appdata'))..createSync();
      File(p.join(target.path, AppDatabase.databaseName))
          .writeAsStringSync('current');

      final moved = await moveLegacyDatabase(
        targetDirectory: target.path,
        legacyDirectories: [legacy.path],
      );

      expect(moved, isNull);
      expect(
        File(p.join(target.path, AppDatabase.databaseName)).readAsStringSync(),
        'current',
      );
    });
  });
}
