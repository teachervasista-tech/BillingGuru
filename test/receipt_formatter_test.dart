import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/printing/receipt_printer_service.dart';
import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/checkout/domain/sale.dart';
import 'package:billing_guru/features/checkout/domain/sale_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Sale sale() => Sale(
    id: 's',
    invoiceNumber: 'INV-1',
    items: const [
      SaleItem(
        id: '1',
        saleId: 's',
        productId: 'a',
        productName: 'Waffelroellchen Long Name',
        quantity: 3,
        unitPriceCents: 159,
        totalCents: 477,
      ),
      SaleItem(
        id: '2',
        saleId: 's',
        productId: 'b',
        productName: 'Tiramisu',
        quantity: 1,
        unitPriceCents: 199,
        totalCents: 199,
      ),
    ],
    subtotalCents: 676,
    discountCents: 0,
    taxCents: 47,
    totalCents: 723,
    paymentMethod: PaymentMethod.card,
    createdAt: DateTime(2026, 10, 17, 15, 42),
    syncStatus: 'pending',
  );

  test('receipt lines fit the fixed width for every template', () {
    for (final template in ReceiptTemplate.values) {
      final text = ReceiptFormatter.format(
        sale(),
        AppCurrency.eur,
        template: template,
        businessDetails: 'Billing Guru\nMain Street 1',
      );
      for (final line in text.split('\n')) {
        expect(line.length, lessThanOrEqualTo(ReceiptFormatter.width));
      }
      expect(text, contains('TOTAL'));
      expect(text, contains('[ LOGO IMAGE ]'));
      expect(text, isNot(contains('Billing Guru')));
      // ignore: avoid_print
      print(text);
    }
  });
}
