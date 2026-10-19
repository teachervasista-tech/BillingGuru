import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// Minimal .xlsx reader: returns the cell text of the first worksheet as rows.
List<List<String>> readFirstWorksheet(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('The file is not a valid .xlsx workbook.');
  }

  List<int>? read(String name) {
    for (final file in archive.files) {
      if (file.isFile && file.name == name) return file.readBytes();
    }
    return null;
  }

  final sharedStrings = <String>[];
  final sharedBytes = read('xl/sharedStrings.xml');
  if (sharedBytes != null) {
    final doc = XmlDocument.parse(utf8.decode(sharedBytes));
    for (final si in doc.findAllElements('si')) {
      sharedStrings.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }

  final sheetNames =
      archive.files
          .where(
            (f) =>
                f.isFile &&
                f.name.startsWith('xl/worksheets/sheet') &&
                f.name.endsWith('.xml'),
          )
          .map((f) => f.name)
          .toList()
        ..sort();
  if (sheetNames.isEmpty) {
    throw const FormatException('The workbook has no worksheets.');
  }

  final sheetBytes = read(sheetNames.first)!;
  final sheet = XmlDocument.parse(utf8.decode(sheetBytes));

  final rows = <List<String>>[];
  for (final row in sheet.findAllElements('row')) {
    final cells = <int, String>{};
    var nextColumn = 0;
    for (final cell in row.findElements('c')) {
      final ref = cell.getAttribute('r');
      final column = ref == null ? nextColumn : _columnIndex(ref);
      nextColumn = column + 1;

      final type = cell.getAttribute('t');
      final raw = cell.getElement('v')?.innerText ?? '';
      String value;
      if (type == 's') {
        final index = int.tryParse(raw);
        value = index != null && index < sharedStrings.length
            ? sharedStrings[index]
            : '';
      } else if (type == 'inlineStr') {
        value = cell.findAllElements('t').map((t) => t.innerText).join();
      } else {
        value = raw;
      }
      cells[column] = value.trim();
    }

    if (cells.isEmpty) continue;
    final width = cells.keys.reduce((a, b) => a > b ? a : b) + 1;
    rows.add([for (var i = 0; i < width; i++) cells[i] ?? '']);
  }
  return rows;
}

int _columnIndex(String cellReference) {
  var index = 0;
  for (final unit in cellReference.toUpperCase().codeUnits) {
    if (unit < 65 || unit > 90) break;
    index = index * 26 + (unit - 64);
  }
  return index - 1;
}
