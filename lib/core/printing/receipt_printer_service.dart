import 'package:billing_guru/core/currency/currency.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'receipt_business_details_provider.dart';
import 'receipt_paper_size.dart';
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
    ReceiptPaperSize paperSize = ReceiptPaperSize.threeInch,
  }) {
    final width = paperSize.columns;
    final receipt = StringBuffer();
    final numberFormat = NumberFormat.decimalPatternDigits(
      locale: currency.locale,
      decimalDigits: currency.decimalDigits,
    );
    String amount(int cents) => numberFormat.format(cents / 100);

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

    // Centers text, wrapping it first so no line runs past the paper width.
    String center(String text) => wrap(text, width)
        .map((line) => '${' ' * ((width - line.length) ~/ 2)}$line')
        .join('\n');

    // Label on the left, value on the right. When both do not fit on one
    // line the label wraps and the value goes right aligned underneath.
    String row(String left, String right) {
      final gap = width - left.length - right.length;
      if (gap > 0) return '$left${' ' * gap}$right';
      return [...wrap(left, width), right.padLeft(width)].join('\n');
    }

    final rule = '-' * width;

    // Item table: name | qty | price | total. The numeric columns start at
    // the paper size defaults and grow to fit the widest value on this
    // receipt, so amounts are never truncated or run into each other. The
    // name column takes whatever width remains.
    final items = [
      for (final item in sale.items)
        (
          name: item.productName?.trim().isNotEmpty == true
              ? item.productName!.trim()
              : item.productId,
          qty: '${item.quantity}',
          price: amount(item.unitPriceCents),
          total: amount(item.totalCents),
        ),
    ];
    int widest(int min, Iterable<String> values, {int gap = 1}) => values
        .map((value) => value.length + gap)
        .fold(min, (a, b) => a > b ? a : b);
    // The name column already leaves a one character gap before qty.
    final qtyWidth = widest(
      paperSize.qtyWidth,
      items.map((i) => i.qty),
      gap: 0,
    );
    final priceWidth = widest(paperSize.priceWidth, items.map((i) => i.price));
    final totalWidth = widest(paperSize.totalWidth, items.map((i) => i.total));
    final nameWidth = width - qtyWidth - priceWidth - totalWidth;
    // With extremely large amounts the name column would become unreadable;
    // the name then gets its own full-width lines above the numbers.
    final stacked = nameWidth < paperSize.minNameWidth;

    // Left-aligned first cell, right-aligned remaining cells. Only the first
    // cell wraps; the other cells always sit on the first line.
    String tableLine(List<String> cells, List<int> widths) {
      final first = wrap(cells.first, widths.first - 1);
      final numbers = [
        for (var i = 1; i < cells.length; i++) cells[i].padLeft(widths[i]),
      ].join();
      return [
        first.first.padRight(widths.first) + numbers,
        ...first.skip(1),
      ].join('\n');
    }

    String tableRow(String name, String qty, String price, String total) {
      if (!stacked) {
        return tableLine(
          [name, qty, price, total],
          [nameWidth, qtyWidth, priceWidth, totalWidth],
        );
      }
      final numbersWidth = qtyWidth + priceWidth + totalWidth;
      return [
        ...wrap(name, width),
        ' ' * (width - numbersWidth) +
            qty.padLeft(qtyWidth) +
            price.padLeft(priceWidth) +
            total.padLeft(totalWidth),
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
    receipt.writeln(wrap('Invoice: ${sale.invoiceNumber}', width).join('\n'));
    receipt.writeln(rule);
    receipt.writeln(tableRow('Item', 'Qty', 'Price', 'Total'));
    receipt.writeln(rule);

    // Every template keeps qty, price and total on the first line of the
    // item name; long names wrap below inside the name column.
    for (final item in items) {
      receipt.writeln(tableRow(item.name, item.qty, item.price, item.total));
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
      // Own column widths so the breakdown never truncates the amounts.
      final netText = amount(net);
      final taxText = amount(sale.taxCents);
      final netWidth = widest(paperSize.priceWidth, [netText]);
      final taxWidth = widest(paperSize.totalWidth, [taxText]);
      final rateWidth = width - netWidth - taxWidth;
      if (rateWidth > 'Tax rate'.length) {
        final widths = [rateWidth, netWidth, taxWidth];
        receipt.writeln(tableLine(['Tax rate', 'Net', 'Tax'], widths));
        receipt.writeln(tableLine(['$rate%', netText, taxText], widths));
      } else {
        receipt.writeln(row('Tax rate', '$rate%'));
        receipt.writeln(row('Net', netText));
        receipt.writeln(row('Tax', taxText));
      }
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
