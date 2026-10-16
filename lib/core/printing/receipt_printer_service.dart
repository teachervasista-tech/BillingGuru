import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'receipt_business_details_provider.dart';
import '../../features/checkout/domain/payment.dart';
import '../../features/checkout/domain/sale.dart';
import '../../features/checkout/domain/sale_item.dart';
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
  }) {
    final receipt = StringBuffer();
    String formatAmount(int cents) {
      return CurrencyFormatter.formatCents(cents, currency: currency);
    }

    for (final line in businessDetails.split(RegExp(r'\r?\n'))) {
      if (line.trim().isNotEmpty) {
        receipt.writeln(line.trim());
      }
    }
    receipt.writeln('SALES RECEIPT');
    receipt.writeln('Invoice: ${sale.invoiceNumber}');
    receipt.writeln('Date: ${DateFormat('dd/MM/yyyy').format(sale.createdAt)}');
    receipt.writeln('Time: ${DateFormat('HH:mm:ss').format(sale.createdAt)}');
    receipt.writeln('------------------------------');
    receipt.writeln('ITEMS');

    for (final item in sale.items) {
      _writeItem(receipt, item, formatAmount, template);
    }

    receipt.writeln('------------------------------');
    receipt.writeln('Subtotal: ${formatAmount(sale.subtotalCents)}');
    if (sale.discountCents > 0) {
      receipt.writeln('Discount: ${formatAmount(sale.discountCents)}');
    }
    receipt.writeln('Tax: ${formatAmount(sale.taxCents)}');
    receipt.writeln('TOTAL: ${formatAmount(sale.totalCents)}');
    receipt.writeln('Payment: ${_paymentLabel(sale.paymentMethod)}');
    receipt.writeln('Thank you for your purchase!');

    return receipt.toString();
  }

  static void _writeItem(
    StringBuffer receipt,
    SaleItem item,
    String Function(int cents) formatAmount,
    ReceiptTemplate template,
  ) {
    final itemName = item.productName?.trim().isNotEmpty == true
        ? item.productName!.trim()
        : item.productId;

    if (template == ReceiptTemplate.detailed) {
      receipt.writeln(
        '$itemName\n'
        '  ${item.quantity} x ${formatAmount(item.unitPriceCents)}'
        ' = ${formatAmount(item.totalCents)}',
      );
      return;
    }

    receipt.writeln(
      '$itemName  ${item.quantity} x ${formatAmount(item.unitPriceCents)}'
      '  ${formatAmount(item.totalCents)}',
    );
  }

  static String _paymentLabel(PaymentMethod paymentMethod) {
    final name = paymentMethod.name;
    return '${name[0].toUpperCase()}${name.substring(1)}';
  }
}
