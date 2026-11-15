import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_info.dart';
import '../database/app_database.dart';
import '../database/migrations.dart';
import '../storage/app_file_storage.dart';

class BackupException implements Exception {
  const BackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BackupManifest {
  const BackupManifest({
    required this.appVersion,
    required this.schemaVersion,
    required this.createdAt,
    this.preferences = const {},
  });

  final String appVersion;
  final int schemaVersion;
  final DateTime createdAt;
  final Map<String, Object> preferences;

  Map<String, Object?> toJson() => {
    'app': AppInfo.name,
    'appVersion': appVersion,
    'schemaVersion': schemaVersion,
    'createdAt': createdAt.toIso8601String(),
    'preferences': preferences,
  };

  factory BackupManifest.fromJson(Map<String, dynamic> json) {
    if (json['app'] != AppInfo.name) {
      throw const BackupException('This is not a Billing Guru backup.');
    }
    return BackupManifest(
      appVersion: json['appVersion'] as String? ?? '?',
      schemaVersion: json['schemaVersion'] as int? ?? 0,
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      preferences: {
        for (final e in (json['preferences'] as Map? ?? const {}).entries)
          if (e.value is String || e.value is int)
            e.key as String: e.value as Object,
      },
    );
  }
}

/// Creates and restores a single-file (.zip) backup containing the
/// database, product images, expense receipts and device preferences.
class BackupService {
  BackupService({
    required this.database,
    Future<Directory> Function()? filesRoot,
    Future<SharedPreferences> Function()? preferences,
  }) : _filesRoot = filesRoot ?? AppFileStorage.root,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final AppDatabase database;
  final Future<Directory> Function() _filesRoot;
  final Future<SharedPreferences> Function() _preferences;

  static const manifestFile = 'billing_guru_backup.json';
  static const databaseEntry = 'database/${AppDatabase.databaseName}';

  /// Device preferences that are not stored in the database.
  static const preferenceKeys = [
    'app_default_tax_rate',
    'payment_options',
    'receipt_template',
    'receipt_paper_size',
  ];

  Future<Uint8List> createArchive({DateTime? now}) async {
    final archive = Archive();
    final temp = await Directory.systemTemp.createTemp('bg_backup_');
    try {
      final snapshot = p.join(temp.path, 'snapshot.db');
      await database.snapshotTo(snapshot);
      archive.addFile(
        ArchiveFile.bytes(databaseEntry, await File(snapshot).readAsBytes()),
      );
    } finally {
      await temp.delete(recursive: true);
    }

    final root = await _filesRoot();
    for (final folder in AppFileStorage.backupFolders) {
      final directory = Directory(p.join(root.path, folder));
      if (!await directory.exists()) continue;
      await for (final entity in directory.list()) {
        if (entity is File) {
          archive.addFile(
            ArchiveFile.bytes(
              'files/$folder/${p.basename(entity.path)}',
              await entity.readAsBytes(),
            ),
          );
        }
      }
    }

    final prefs = await _preferences();
    final manifest = BackupManifest(
      appVersion: AppInfo.version,
      schemaVersion: latestSchemaVersion,
      createdAt: now ?? DateTime.now(),
      preferences: {
        for (final key in preferenceKeys)
          if (prefs.get(key) case final Object value
              when value is String || value is int)
            key: value,
      },
    );
    archive.addFile(
      ArchiveFile.bytes(
        manifestFile,
        utf8.encode(jsonEncode(manifest.toJson())),
      ),
    );

    return Uint8List.fromList(ZipEncoder().encode(archive));
  }

  /// Reads the manifest without restoring (for a confirmation prompt).
  BackupManifest inspect(Uint8List bytes) => _readManifest(_decode(bytes));

  /// Replaces all current data with the backup's.
  Future<BackupManifest> restoreArchive(Uint8List bytes) async {
    final archive = _decode(bytes);
    final manifest = _readManifest(archive);
    if (manifest.schemaVersion > latestSchemaVersion) {
      throw BackupException(
        'This backup was made by a newer version of Billing Guru '
        '(${manifest.appVersion}). Update the app first.',
      );
    }
    final dbEntry = archive.findFile(databaseEntry);
    if (dbEntry == null) {
      throw const BackupException('The backup does not contain a database.');
    }
    final dbBytes = dbEntry.content;
    if (dbBytes.length < 16 ||
        utf8.decode(dbBytes.sublist(0, 15), allowMalformed: true) !=
            'SQLite format 3') {
      throw const BackupException('The backup database is damaged.');
    }

    final temp = await Directory.systemTemp.createTemp('bg_restore_');
    try {
      final restored = File(p.join(temp.path, 'restore.db'));
      await restored.writeAsBytes(dbBytes, flush: true);
      await database.replaceWith(restored);
    } finally {
      await temp.delete(recursive: true);
    }

    final root = await _filesRoot();
    for (final folder in AppFileStorage.backupFolders) {
      final directory = Directory(p.join(root.path, folder));
      if (await directory.exists()) await directory.delete(recursive: true);
      await directory.create(recursive: true);
    }
    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('files/')) continue;
      final parts = file.name.split('/');
      if (parts.length != 3 ||
          !AppFileStorage.backupFolders.contains(parts[1])) {
        continue; // Ignore anything unexpected (no path traversal).
      }
      final name = p.basename(parts[2]);
      await File(p.join(root.path, parts[1], name))
          .writeAsBytes(file.content, flush: true);
    }

    await _relinkFiles(root);

    final prefs = await _preferences();
    for (final entry in manifest.preferences.entries) {
      final value = entry.value;
      if (value is int) {
        await prefs.setInt(entry.key, value);
      } else if (value is String) {
        await prefs.setString(entry.key, value);
      }
    }
    return manifest;
  }

  /// Stored file paths are absolute; point them at this machine's folders.
  Future<void> _relinkFiles(Directory root) async {
    final db = await database.database;
    for (final (table, column, folder) in [
      ('products', 'image_path', AppFileStorage.productImagesFolder),
      ('expenses', 'attachment_path', AppFileStorage.expenseAttachmentsFolder),
    ]) {
      final rows = await db.query(
        table,
        columns: ['id', column],
        where: '$column IS NOT NULL',
      );
      for (final row in rows) {
        final old = row[column] as String;
        // Handle both Windows and POSIX separators from the source machine.
        final name = old.split(RegExp(r'[\\/]')).last;
        await db.update(
          table,
          {column: p.join(root.path, folder, name)},
          where: 'id = ?',
          whereArgs: [row['id']],
        );
      }
    }
  }

  Archive _decode(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupException('The file is not a valid backup archive.');
    }
  }

  BackupManifest _readManifest(Archive archive) {
    final entry = archive.findFile(manifestFile);
    if (entry == null) {
      throw const BackupException('This is not a Billing Guru backup.');
    }
    try {
      return BackupManifest.fromJson(
        jsonDecode(utf8.decode(entry.content)) as Map<String, dynamic>,
      );
    } on BackupException {
      rethrow;
    } catch (_) {
      throw const BackupException('The backup manifest is damaged.');
    }
  }
}
