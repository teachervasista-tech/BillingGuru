import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:billing_guru/features/products/data/services/product_import.dart';
import 'package:billing_guru/features/products/data/services/xlsx_reader.dart';
import 'package:flutter_test/flutter_test.dart';

Uint8List _workbook() {
  const shared =
      '<sst><si><t>Name</t></si><si><t>Category</t></si><si><t>Price</t></si>'
      '<si><t>Stock</t></si><si><t>Tea</t></si><si><t>Drinks</t></si></sst>';
  const sheet =
      '<worksheet><sheetData>'
      '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c>'
      '<c r="C1" t="s"><v>2</v></c><c r="D1" t="s"><v>3</v></c></row>'
      '<row r="2"><c r="A2" t="s"><v>4</v></c><c r="B2" t="s"><v>5</v></c>'
      '<c r="C2"><v>2.5</v></c><c r="D2"><v>12</v></c></row>'
      '<row r="3"><c r="A3" t="inlineStr"><is><t>Coffee</t></is></c>'
      '<c r="C3"><v>abc</v></c></row>'
      '</sheetData></worksheet>';
  final archive = Archive()
    ..addFile(ArchiveFile.bytes('xl/sharedStrings.xml', utf8.encode(shared)))
    ..addFile(
      ArchiveFile.bytes('xl/worksheets/sheet1.xml', utf8.encode(sheet)),
    );
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

void main() {
  test('reads a workbook and builds products', () {
    final rows = readFirstWorksheet(_workbook());
    expect(rows.first, ['Name', 'Category', 'Price', 'Stock']);

    final parsed = parseProductRows(rows, defaultTaxRate: 19);
    expect(parsed.products, hasLength(1));
    final tea = parsed.products.single;
    expect(tea.name, 'Tea');
    expect(tea.category, 'Drinks');
    expect(tea.priceCents, 250);
    expect(tea.stockQuantity, 12);
    expect(tea.taxRate, 19);
    expect(parsed.errors.single, contains('Row 3'));
  });

  test('rejects a sheet without the required columns', () {
    final parsed = parseProductRows([
      ['Foo'],
    ], defaultTaxRate: 0);
    expect(parsed.products, isEmpty);
    expect(parsed.errors, isNotEmpty);
  });

  test('rejects a file that is not xlsx', () {
    expect(
      () => readFirstWorksheet(Uint8List.fromList([1, 2, 3])),
      throwsFormatException,
    );
  });
}
