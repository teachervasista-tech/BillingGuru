import 'package:billing_guru/features/checkout/domain/invoice_sequence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final date = DateTime(2026, 10, 19);

  test('parses the configured reset period', () {
    expect(InvoiceSequenceReset.parse('daily\n'), InvoiceSequenceReset.daily);
    expect(
      InvoiceSequenceReset.parse(' MONTHLY '),
      InvoiceSequenceReset.monthly,
    );
    expect(InvoiceSequenceReset.parse('Yearly'), InvoiceSequenceReset.yearly);
    expect(InvoiceSequenceReset.parse('nonsense'), InvoiceSequenceReset.daily);
    expect(InvoiceSequenceReset.parse(null), InvoiceSequenceReset.daily);
  });

  test('prefix changes only when the period changes', () {
    expect(InvoiceSequenceReset.daily.format(date, 1), 'INV-20261019-0001');
    expect(InvoiceSequenceReset.monthly.format(date, 12), 'INV-202610-0012');
    expect(InvoiceSequenceReset.yearly.format(date, 3), 'INV-2026-0003');
    expect(
      InvoiceSequenceReset.daily.prefixFor(DateTime(2026, 10, 20)),
      isNot(InvoiceSequenceReset.daily.prefixFor(date)),
    );
    expect(
      InvoiceSequenceReset.monthly.prefixFor(DateTime(2026, 10, 31)),
      InvoiceSequenceReset.monthly.prefixFor(date),
    );
  });
}
