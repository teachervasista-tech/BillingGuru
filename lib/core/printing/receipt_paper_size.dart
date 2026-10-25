import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';

import '../currency/currency_provider.dart';

enum ReceiptPaperSize { twoInch, threeInch }

extension ReceiptPaperSizeDetails on ReceiptPaperSize {
  String get label {
    return switch (this) {
      ReceiptPaperSize.twoInch => '2" (58 mm)',
      ReceiptPaperSize.threeInch => '3" (80 mm)',
    };
  }

  /// Characters that fit on one printed line.
  int get columns {
    return switch (this) {
      ReceiptPaperSize.twoInch => 32,
      ReceiptPaperSize.threeInch => 42,
    };
  }

  int get qtyWidth => this == ReceiptPaperSize.twoInch ? 3 : 4;
  int get priceWidth => this == ReceiptPaperSize.twoInch ? 8 : 10;
  int get totalWidth => this == ReceiptPaperSize.twoInch ? 9 : 11;

  PdfPageFormat get pageFormat {
    return switch (this) {
      // Atpos H58 uses 58 mm paper with a 48 mm printable width.
      ReceiptPaperSize.twoInch => const PdfPageFormat(
        58 * PdfPageFormat.mm,
        double.infinity,
      ),
      // 80 mm paper with a 72 mm printable width.
      ReceiptPaperSize.threeInch => const PdfPageFormat(
        80 * PdfPageFormat.mm,
        double.infinity,
      ),
    };
  }

  /// Blank space kept on the left and right so text stays in the printable area.
  double get horizontalMargin {
    return switch (this) {
      ReceiptPaperSize.twoInch => 5 * PdfPageFormat.mm,
      ReceiptPaperSize.threeInch => 4 * PdfPageFormat.mm,
    };
  }

  /// Courier glyphs are 0.6 em wide; sized so [columns] fill the printable width.
  double get fontSize {
    final printable = pageFormat.width - 2 * horizontalMargin;
    return printable / (columns * 0.6);
  }
}

ReceiptPaperSize receiptPaperSizeFromName(String? name) {
  return ReceiptPaperSize.values.firstWhere(
    (size) => size.name == name,
    orElse: () => ReceiptPaperSize.threeInch,
  );
}

final receiptPaperSizeProvider =
    NotifierProvider<ReceiptPaperSizeNotifier, ReceiptPaperSize>(
      ReceiptPaperSizeNotifier.new,
    );

class ReceiptPaperSizeNotifier extends Notifier<ReceiptPaperSize> {
  static const _preferenceKey = 'receipt_paper_size';

  @override
  ReceiptPaperSize build() {
    _load();
    return ReceiptPaperSize.threeInch;
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      state = receiptPaperSizeFromName(prefs.getString(_preferenceKey));
    } catch (_) {
      state = ReceiptPaperSize.threeInch;
    }
  }

  Future<void> select(ReceiptPaperSize size) async {
    state = size;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_preferenceKey, size.name);
  }
}
