import 'package:billing_guru/core/currency/currency.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'receipt_business_details_provider.dart';
import '../../features/checkout/domain/payment.dart';
import '../../features/checkout/domain/sale.dart';
import 'receipt_template.dart';

abstract class ReceiptPrinterService {
  Future<void> printReceipt(
    Sale sale,
    AppCurrency currency, {
    ReceiptTemplate template = ReceiptTemplate.classic,
  });
}

class ReceiptPrinterPreviewService implements ReceiptPrinterService {
  @override
  Future<void> printReceipt(
    Sale sale,
    AppCurrency currency, {
    ReceiptTemplate template = ReceiptTemplate.classic,
  }) async {
    final businessDetails = (await rootBundle.loadString(
      receiptBusinessDetailsAssetPath,
    )).trim();
    // ignore: avoid_print
    print(
      ReceiptFormatter.format(
        sale,
        currency,
        template: template,
        businessDetails: businessDetails,
      ),
    );
  }
}

class ReceiptFormatter {
  const ReceiptFormatter._();

  static String format(
    Sale sale,
    AppCurrency currency, {
    required ReceiptTemplate template,
    required String businessDetails,
    bool showLogoPlaceholder = true,
  }) {
    final receipt = StringBuffer();
    final numberFormat = NumberFormat.decimalPatternDigits(
      locale: currency.locale,
      decimalDigits: currency.decimalDigits,
    );
    String amount(int cents) => numberFormat.format(cents / 100);
    String center(String text) {
      final padding = (width - text.length) ~/ 2;
      return text.length >= width ? text : '${' ' * padding}$text';
    }

    String row(String left, String right) {
      final gap = width - left.length - right.length;
      return gap > 0 ? '$left${' ' * gap}$right' : '$left $right';
    }

    final rule = '-' * width;

    // Fixed-width table columns: item | qty | price | total.
    const qtyWidth = 4;
    const priceWidth = 10;
    const totalWidth = 11;
    const nameWidth = width - qtyWidth - priceWidth - totalWidth;

    // Splits text into chunks of at most [max] characters, preferring spaces.
    List<String> wrap(String text, int max) {
      final lines = <String>[];
      var rest = text.trim();
      while (rest.length > max) {
        var cut = rest.lastIndexOf(' ', max);
        if (cut <= 0) cut = max;
        lines.add(rest.substring(0, cut).trimRight());
        rest = rest.substring(cut).trimLeft();
      }
      lines.add(rest);
      return lines;
    }

    // Each cell wraps inside its own fixed-width column. Text is left
    // aligned; numeric columns are right aligned.
    String tableRow(String name, String qty, String price, String total) {
      final cols = [
        wrap(name, nameWidth - 1),
        wrap(qty, qtyWidth),
        wrap(price, priceWidth),
        wrap(total, totalWidth),
      ];
      final height = cols.map((c) => c.length).reduce((a, b) => a > b ? a : b);
      String cell(List<String> lines, int i) =>
          i < lines.length ? lines[i] : '';
      return [
        for (var i = 0; i < height; i++)
          cell(cols[0], i).padRight(nameWidth) +
              cell(cols[1], i).padLeft(qtyWidth) +
              cell(cols[2], i).padLeft(priceWidth) +
              cell(cols[3], i).padLeft(totalWidth),
      ].join('\n');
    }

    // The first business detail line is the business name, which the logo
    // placeholder replaces.
    final detailLines = businessDetails
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .skip(1);

    final compact = template == ReceiptTemplate.compact;
    const logoInner = 20;
    if (!showLogoPlaceholder) {
      // A real logo image is rendered above the text instead.
    } else if (compact) {
      receipt.writeln(center('[ LOGO IMAGE ]'));
    } else {
      receipt.writeln(center('+${'-' * logoInner}+'));
      for (var i = 0; i < 3; i++) {
        final text = i == 1 ? '[ LOGO IMAGE ]' : '';
        final left = (logoInner - text.length) ~/ 2;
        receipt.writeln(
          center(
            '|${' ' * left}$text${' ' * (logoInner - left - text.length)}|',
          ),
        );
      }
      receipt.writeln(center('+${'-' * logoInner}+'));
      receipt.writeln();
    }
    for (final line in detailLines) {
      receipt.writeln(center(line));
    }
    if (!compact) receipt.writeln();
    receipt.writeln(
      row(
        DateFormat('dd/MM/yyyy').format(sale.createdAt),
        DateFormat('HH:mm:ss').format(sale.createdAt),
      ),
    );
    receipt.writeln('Invoice: ${sale.invoiceNumber}');
    receipt.writeln(rule);
    receipt.writeln(tableRow('Item', 'Qty', 'Price', 'Total'));
    receipt.writeln(rule);

    for (final item in sale.items) {
      final name = item.productName?.trim().isNotEmpty == true
          ? item.productName!.trim()
          : item.productId;
      final price = amount(item.unitPriceCents);
      final total = amount(item.totalCents);

      if (template == ReceiptTemplate.detailed) {
        for (final line in wrap(name, width)) {
          receipt.writeln(line);
        }
        receipt.writeln(tableRow('', '${item.quantity}', price, total));
        continue;
      }

      receipt.writeln(tableRow(name, '${item.quantity}', price, total));
    }

    receipt.writeln(rule);
    receipt.writeln(row('Subtotal', amount(sale.subtotalCents)));
    if (sale.discountCents > 0) {
      receipt.writeln(row('Discount', '-${amount(sale.discountCents)}'));
    }
    final net = sale.subtotalCents - sale.discountCents;
    final rate = net > 0 ? (sale.taxCents * 100 / net).round() : 0;
    receipt.writeln(row('Tax ($rate%)', amount(sale.taxCents)));
    receipt.writeln(rule);
    receipt.writeln(row('TOTAL (${currency.code})', amount(sale.totalCents)));
    receipt.writeln(rule);
    receipt.writeln(row('Payment', _paymentLabel(sale.paymentMethod)));

    if (template == ReceiptTemplate.detailed) {
      receipt.writeln();
      receipt.writeln(tableRow('Tax rate', '', 'Net', 'Tax'));
      receipt.writeln(
        tableRow('$rate%', '', amount(net), amount(sale.taxCents)),
      );
    }

    if (!compact) receipt.writeln();
    receipt.writeln(center('Thank you for your purchase!'));

    return receipt.toString();
  }

  static const int width = 42;

  static String _paymentLabel(PaymentMethod paymentMethod) {
    return switch (paymentMethod) {
      PaymentMethod.cash => 'Cash',
      PaymentMethod.card => 'Card',
      PaymentMethod.digital => 'Digital',
    };
  }
}
