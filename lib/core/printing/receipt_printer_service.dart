import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/currency/currency_formatter.dart';

import '../../features/checkout/domain/sale.dart';

abstract class ReceiptPrinterService {
  Future<void> printReceipt(Sale sale, AppCurrency currency);
}

class ReceiptPrinterPreviewService implements ReceiptPrinterService {
  @override
  Future<void> printReceipt(Sale sale, AppCurrency currency) async {
    final receipt = StringBuffer();

    receipt.writeln('POS BILLING');
    receipt.writeln('------------------------------');
    receipt.writeln('Invoice: ${sale.invoiceNumber}');
    receipt.writeln('Date: ${sale.createdAt}');
    receipt.writeln('------------------------------');

    for (final item in sale.items) {
      receipt.writeln(
        '${item.productId} x${item.quantity} '
        '${CurrencyFormatter.formatCents(item.totalCents, currency: currency)}',
      );
    }

    receipt.writeln('------------------------------');
    receipt.writeln(
      'Subtotal: ${CurrencyFormatter.formatCents(sale.subtotalCents, currency: currency)}',
    );
    receipt.writeln(
      'Tax: ${CurrencyFormatter.formatCents(sale.taxCents, currency: currency)}',
    );
    receipt.writeln(
      'Total: ${CurrencyFormatter.formatCents(sale.totalCents, currency: currency)}',
    );
    receipt.writeln('Payment: ${sale.paymentMethod.name}');

    // ignore: avoid_print
    print(receipt.toString());
  }
}
