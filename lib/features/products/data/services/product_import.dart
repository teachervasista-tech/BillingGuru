import '../models/product.dart';

class ProductImportResult {
  const ProductImportResult({required this.added, required this.errors});

  final int added;
  final List<String> errors;
}

class ParsedProductRows {
  const ParsedProductRows({required this.products, required this.errors});

  final List<Product> products;
  final List<String> errors;
}

/// Columns (header row, case-insensitive): Name, Price are required;
/// Category, Short code, Barcode, Tax rate, Stock are optional.
const productImportColumns =
    'Name, Category, Short code, Barcode, Price, Tax rate, Stock';

ParsedProductRows parseProductRows(
  List<List<String>> rows, {
  required int defaultTaxRate,
}) {
  if (rows.isEmpty) {
    return const ParsedProductRows(
      products: [],
      errors: ['The sheet is empty.'],
    );
  }

  String key(String header) =>
      header.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '');
  final headers = rows.first.map(key).toList();
  int column(List<String> names) {
    for (final name in names) {
      final index = headers.indexOf(name);
      if (index >= 0) return index;
    }
    return -1;
  }

  final nameCol = column(['name', 'productname', 'product']);
  final categoryCol = column(['category']);
  final shortCol = column(['shortcode', 'code', 'sku']);
  final barcodeCol = column(['barcode']);
  final priceCol = column(['price', 'unitprice']);
  final taxCol = column(['taxrate', 'tax']);
  final stockCol = column(['stock', 'quantity', 'stockquantity']);

  if (nameCol < 0 || priceCol < 0) {
    return const ParsedProductRows(
      products: [],
      errors: ['The first row must contain "Name" and "Price" columns.'],
    );
  }

  String cell(List<String> row, int col) =>
      col >= 0 && col < row.length ? row[col].trim() : '';

  final products = <Product>[];
  final errors = <String>[];
  final seenCodes = <String>{};
  final seenBarcodes = <String>{};
  final stamp = DateTime.now().microsecondsSinceEpoch;

  for (var i = 1; i < rows.length; i++) {
    final row = rows[i];
    final line = i + 1;
    if (row.every((value) => value.trim().isEmpty)) continue;

    final name = cell(row, nameCol);
    final price = double.tryParse(cell(row, priceCol).replaceAll(',', '.'));
    if (name.isEmpty) {
      errors.add('Row $line: name is missing.');
      continue;
    }
    if (price == null || price < 0) {
      errors.add('Row $line: invalid price "${cell(row, priceCol)}".');
      continue;
    }

    final taxText = cell(row, taxCol);
    final tax = taxText.isEmpty
        ? defaultTaxRate
        : double.tryParse(taxText.replaceAll(',', '.'))?.round();
    final stockText = cell(row, stockCol);
    final stock = stockText.isEmpty
        ? 0
        : double.tryParse(stockText.replaceAll(',', '.'))?.round();
    if (tax == null || tax < 0 || stock == null || stock < 0) {
      errors.add('Row $line: invalid tax rate or stock.');
      continue;
    }

    var shortCode = cell(row, shortCol).toUpperCase();
    if (shortCode.isEmpty) {
      shortCode = 'IMP${(stamp + i).toRadixString(36).toUpperCase()}';
    }
    final barcode = cell(row, barcodeCol);
    if (!seenCodes.add(shortCode)) {
      errors.add('Row $line: short code $shortCode is repeated in the file.');
      continue;
    }
    if (barcode.isNotEmpty && !seenBarcodes.add(barcode)) {
      errors.add('Row $line: barcode $barcode is repeated in the file.');
      continue;
    }

    final category = cell(row, categoryCol);
    products.add(
      Product(
        id: 'p-${stamp + i}',
        shortCode: shortCode,
        barcode: barcode,
        name: name,
        category: category.isEmpty ? 'Other' : category,
        priceCents: (price * 100).round(),
        taxRate: tax,
        stockQuantity: stock,
      ),
    );
  }

  return ParsedProductRows(products: products, errors: errors);
}
