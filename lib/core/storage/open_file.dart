import 'dart:io';

/// Opens [path] with the operating system's default application.
Future<bool> openWithSystem(String path) async {
  if (!await File(path).exists()) return false;
  try {
    if (Platform.isWindows) {
      await Process.start('explorer', [path]);
    } else if (Platform.isMacOS) {
      await Process.start('open', [path]);
    } else if (Platform.isLinux) {
      await Process.start('xdg-open', [path]);
    } else {
      return false;
    }
    return true;
  } catch (_) {
    return false;
  }
}
