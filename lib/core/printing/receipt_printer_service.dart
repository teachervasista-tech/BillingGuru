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
        '${item.productId} x${item.quantity} ${_formatMoney(item.totalCents)}',
      );
    }

    receipt.writeln('------------------------------');
    receipt.writeln('Subtotal: ${_formatMoney(sale.subtotalCents)}');
    receipt.writeln('Tax: ${_formatMoney(sale.taxCents)}');
    receipt.writeln('Total: ${_formatMoney(sale.totalCents)}');
    receipt.writeln('Payment: ${sale.paymentMethod.name}');

    // ignore: avoid_print
    print(receipt.toString());
  }

  String _formatMoney(int cents) {
    return '₹${(cents / 100).toStringAsFixed(2)}';
  }
}
