import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/printing/receipt_paper_size.dart';
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

  test('receipt lines fit the fixed width for every template and size', () {
    for (final size in ReceiptPaperSize.values) {
      for (final template in ReceiptTemplate.values) {
        final text = ReceiptFormatter.format(
          sale(),
          AppCurrency.eur,
          template: template,
          businessDetails: 'Billing Guru\nMain Street 1',
          paperSize: size,
        );
        for (final line in text.split('\n')) {
          expect(line.length, lessThanOrEqualTo(size.columns));
        }
        expect(text, contains('TOTAL'));
        expect(text, contains('[ LOGO IMAGE ]'));
        expect(text, isNot(contains('Billing Guru')));
      }
    }
  });

  test('qty, price and total sit on the first line of a wrapped name', () {
    for (final size in ReceiptPaperSize.values) {
      for (final template in ReceiptTemplate.values) {
        final lines = ReceiptFormatter.format(
          sale(),
          AppCurrency.eur,
          template: template,
          businessDetails: 'Billing Guru',
          paperSize: size,
        ).split('\n');
        final header = lines.firstWhere((l) => l.startsWith('Item'));
        final first = lines.indexWhere((l) => l.startsWith('Waffelroell'));
        expect(lines[first], endsWith('4,77'), reason: '$size $template');
        expect(lines[first], contains(' 3 '), reason: '$size $template');
        expect(lines[first], contains(' 1,59 '), reason: '$size $template');
        // Numbers line up under their headers.
        expect(lines[first].length, header.length);
        expect(lines[first + 1].trim(), isNot(contains('4,77')));
        final tiramisu = lines.firstWhere((l) => l.startsWith('Tiramisu'));
        expect(tiramisu, endsWith('1,99'), reason: '$size $template');
      }
    }
  });

  test('large amounts and long details are never truncated or overflow', () {
    final big = Sale(
      id: 'b',
      invoiceNumber: 'INV-20261114-000123',
      items: const [
        SaleItem(
          id: '1',
          saleId: 'b',
          productId: 'a',
          productName: 'Big ticket item',
          quantity: 150,
          unitPriceCents: 1234599,
          totalCents: 185189850,
        ),
      ],
      subtotalCents: 185189850,
      discountCents: 0,
      taxCents: 12345678,
      totalCents: 197535528,
      paymentMethod: PaymentMethod.card,
      createdAt: DateTime(2026, 10, 17, 15, 42),
      syncStatus: 'pending',
    );
    for (final size in ReceiptPaperSize.values) {
      for (final template in ReceiptTemplate.values) {
        final text = ReceiptFormatter.format(
          big,
          AppCurrency.eur,
          template: template,
          businessDetails:
              'Billing Guru\nMain Street 1, 12345 Some Very Long City Name',
          paperSize: size,
        );
        for (final line in text.split('\n')) {
          expect(line.length, lessThanOrEqualTo(size.columns));
        }
        final numbers = text
            .split('\n')
            .firstWhere((l) => l.contains('12.345,99'));
        expect(numbers, matches(RegExp(r' 150 +12\.345,99 +1\.851\.898,50$')));
        expect(text, contains('City'));
      }
    }
  });
}
