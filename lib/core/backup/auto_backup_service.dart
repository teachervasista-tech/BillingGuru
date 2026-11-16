import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/app_file_storage.dart';
import 'backup_service.dart';

/// Outcome of the latest automatic backup, kept on this computer only.
class AutoBackupStatus {
  const AutoBackupStatus({
    this.folder,
    this.lastAt,
    this.lastPath,
    this.lastError,
  });

  /// Folder chosen in Settings → Data (null: default local folder).
  final String? folder;
  final DateTime? lastAt;
  final String? lastPath;

  /// Set when the latest attempt failed (or fell back to the local folder).
  final String? lastError;
}

/// Writes a daily backup archive (one file per day, the latest run of the
/// day wins) and keeps the newest [keep] files.
class AutoBackupService {
  AutoBackupService({
    required this.backup,
    Future<Directory> Function()? defaultFolder,
    Future<SharedPreferences> Function()? preferences,
    this.keep = 30,
  }) : _defaultFolder = defaultFolder ?? _localBackupFolder,
       _preferences = preferences ?? SharedPreferences.getInstance;

  final BackupService backup;
  final int keep;
  final Future<Directory> Function() _defaultFolder;
  final Future<SharedPreferences> Function() _preferences;

  static const folderKey = 'auto_backup_folder';
  static const lastAtKey = 'auto_backup_last_at';
  static const lastPathKey = 'auto_backup_last_path';
  static const lastErrorKey = 'auto_backup_last_error';
  static const filePrefix = 'billing-guru-auto-';

  static Future<Directory> _localBackupFolder() =>
      AppFileStorage.folder('backups');

  Future<Directory> defaultFolder() => _defaultFolder();

  static String fileNameFor(DateTime day) =>
      '$filePrefix${DateFormat('yyyy-MM-dd').format(day)}.zip';

  Future<AutoBackupStatus> status() async {
    final prefs = await _preferences();
    return AutoBackupStatus(
      folder: prefs.getString(folderKey),
      lastAt: DateTime.tryParse(prefs.getString(lastAtKey) ?? ''),
      lastPath: prefs.getString(lastPathKey),
      lastError: prefs.getString(lastErrorKey),
    );
  }

  /// Sets (or with null, clears) the folder backups are written to.
  Future<void> setFolder(String? folder) async {
    final prefs = await _preferences();
    if (folder == null || folder.isEmpty) {
      await prefs.remove(folderKey);
    } else {
      await prefs.setString(folderKey, folder);
    }
  }

  /// Runs a backup unless one was already made today.
  Future<AutoBackupStatus> runIfDue({DateTime? now}) async {
    final current = now ?? DateTime.now();
    final last = (await status()).lastAt;
    if (last != null && _sameDay(last, current)) return status();
    return run(now: current);
  }

  /// Writes today's backup into the chosen folder, falling back to the local
  /// folder when the chosen one is unavailable (e.g. USB drive unplugged).
  /// Never throws; the outcome is recorded in [status]. Runs one at a time.
  Future<AutoBackupStatus> run({DateTime? now}) {
    final next = _queue
        .catchError((_) => const AutoBackupStatus())
        .then((_) => _run(now ?? DateTime.now()));
    _queue = next;
    return next;
  }

  Future<AutoBackupStatus> _queue = Future.value(const AutoBackupStatus());

  Future<AutoBackupStatus> _run(DateTime current) async {
    final prefs = await _preferences();
    final chosen = prefs.getString(folderKey);

    List<int> bytes;
    try {
      bytes = await backup.createArchive(now: current);
    } catch (error) {
      await prefs.setString(lastErrorKey, 'Backup failed: $error');
      return status();
    }

    String? warning;
    String? written;
    if (chosen != null) {
      try {
        written = await _write(Directory(chosen), bytes, current);
      } catch (error) {
        warning =
            'Backup folder "$chosen" was not available, so the backup was '
            'saved on this computer instead. ($error)';
      }
    }
    if (written == null) {
      try {
        written = await _write(await _defaultFolder(), bytes, current);
      } catch (error) {
        await prefs.setString(lastErrorKey, 'Backup failed: $error');
        return status();
      }
    }

    await prefs.setString(lastAtKey, current.toIso8601String());
    await prefs.setString(lastPathKey, written);
    if (warning == null) {
      await prefs.remove(lastErrorKey);
    } else {
      await prefs.setString(lastErrorKey, warning);
    }
    return status();
  }

  Future<String> _write(Directory folder, List<int> bytes, DateTime now) async {
    if (!await folder.exists()) {
      throw FileSystemException('Folder not found', folder.path);
    }
    final target = File(p.join(folder.path, fileNameFor(now)));
    // Write next to the target, then swap, so a crash never leaves a
    // half-written backup in place of a good one.
    final partial = File('${target.path}.partial');
    await partial.writeAsBytes(bytes, flush: true);
    if (await target.exists()) await target.delete();
    await partial.rename(target.path);
    await _prune(folder);
    return target.path;
  }

  Future<void> _prune(Directory folder) async {
    final backups = <File>[
      await for (final entity in folder.list())
        if (entity is File &&
            p.basename(entity.path).startsWith(filePrefix) &&
            entity.path.endsWith('.zip'))
          entity,
    ];
    if (backups.length <= keep) return;
    // Names embed the date, so name order is age order.
    backups.sort((a, b) => p.basename(b.path).compareTo(p.basename(a.path)));
    for (final old in backups.skip(keep)) {
      try {
        await old.delete();
      } catch (_) {
        // A locked old backup is not worth failing the run over.
      }
    }
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
