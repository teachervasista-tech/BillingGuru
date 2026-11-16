import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_database.dart';

Future<void> initializePlatformDatabase() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final support = await getApplicationSupportDirectory();
    final directory = p.join(support.path, 'database');
    await moveLegacyDatabase(
      targetDirectory: directory,
      legacyDirectories: legacyDatabaseDirectories(),
    );
    await databaseFactory.setDatabasesPath(directory);
  }
}

/// Before 2.1.0 the desktop database lived in `.dart_tool\sqflite_common_ffi\
/// databases` relative to the folder the app was started from, so it could
/// "disappear" when the app was launched from somewhere else.
List<String> legacyDatabaseDirectories() {
  const relative = ['.dart_tool', 'sqflite_common_ffi', 'databases'];
  final roots = <String>{
    Directory.current.path,
    p.dirname(Platform.resolvedExecutable),
  };
  return [
    for (final root in roots) p.joinAll([root, ...relative]),
  ];
}

/// Copies the newest legacy database into [targetDirectory] when no database
/// exists there yet. The legacy file is left in place as a safety copy.
/// Returns the path that was copied, or null.
@visibleForTesting
Future<String?> moveLegacyDatabase({
  required String targetDirectory,
  required List<String> legacyDirectories,
}) async {
  final target = File(p.join(targetDirectory, AppDatabase.databaseName));
  if (await target.exists()) return null;

  File? newest;
  DateTime? newestModified;
  for (final directory in legacyDirectories) {
    final candidate = File(p.join(directory, AppDatabase.databaseName));
    if (!await candidate.exists()) continue;
    final modified = await candidate.lastModified();
    if (newestModified == null || modified.isAfter(newestModified)) {
      newest = candidate;
      newestModified = modified;
    }
  }
  if (newest == null) return null;

  await Directory(targetDirectory).create(recursive: true);
  // Copy the write-ahead log too so no committed data is lost.
  for (final suffix in ['', '-wal', '-shm', '-journal']) {
    final source = File('${newest.path}$suffix');
    if (await source.exists()) await source.copy('${target.path}$suffix');
  }
  return newest.path;
}
