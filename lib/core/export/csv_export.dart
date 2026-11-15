import 'dart:convert';
import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// Minimal RFC 4180 CSV writer (opens in Excel / LibreOffice).
class CsvExport {
  const CsvExport._();

  static String encode(List<List<Object?>> rows) {
    String cell(Object? value) {
      final text = value?.toString() ?? '';
      final needsQuotes =
          text.contains(',') ||
          text.contains('"') ||
          text.contains('\n') ||
          text.contains('\r');
      return needsQuotes ? '"${text.replaceAll('"', '""')}"' : text;
    }

    return rows.map((row) => row.map(cell).join(',')).join('\r\n');
  }

  /// Asks where to save and writes [rows]; returns the path or null when
  /// cancelled. A UTF-8 BOM is added so Excel detects the encoding.
  static Future<String?> save({
    required String suggestedName,
    required List<List<Object?>> rows,
  }) async {
    final location = await getSaveLocation(
      suggestedName: suggestedName,
      acceptedTypeGroups: const [
        XTypeGroup(label: 'CSV', extensions: ['csv']),
      ],
    );
    if (location == null) return null;
    final file = File(location.path);
    await file.writeAsBytes([
      0xEF,
      0xBB,
      0xBF,
      ...utf8.encode(encode(rows)),
    ], flush: true);
    return file.path;
  }

  /// Plain decimal amount for spreadsheets (no currency symbol).
  static String amount(int cents) => (cents / 100).toStringAsFixed(2);
}
