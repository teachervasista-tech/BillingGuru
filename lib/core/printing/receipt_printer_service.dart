import '../../features/checkout/domain/sale.dart';

abstract class ReceiptPrinterService {
  Future<void> printReceipt(Sale sale);
}

class ReceiptPrinterPreviewService implements ReceiptPrinterService {
  @override
  Future<void> printReceipt(Sale sale) async {
    final receipt = StringBuffer();

    receipt.writeln('POS BILLING');
    receipt.writeln('------------------------------');
    receipt.writeln('Invoice: ${sale.invoiceNumber}');
    receipt.writeln('Date: ${sale.createdAt}');
    receipt.writeln('------------------------------');

    for (final item in sale.items) {
      receipt.writeln(
        '${item.productId} x${item.quantity} '
        '${formatMoney(item.totalCents)}',
      );
    }

    receipt.writeln('------------------------------');
    receipt.writeln('Subtotal: ${formatMoney(sale.subtotalCents)}');
    receipt.writeln('Tax: ${formatMoney(sale.taxCents)}');
    receipt.writeln('Total: ${formatMoney(sale.totalCents)}');
    receipt.writeln('Payment: ${sale.paymentMethod.name}');

    // Temporary implementation.
    // Replace this with a Bluetooth, USB, or LAN printer call.
    assert(() {
      // ignore: avoid_print
      print(receipt.toString());
      return true;
    }());
  }

  String formatMoney(int cents) {
    return '€${(cents / 100).toStringAsFixed(2)}';
  }
}
