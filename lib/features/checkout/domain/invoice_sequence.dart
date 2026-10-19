import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const invoiceSequenceAssetPath = 'assets/config/invoice_sequence.txt';

/// How often the invoice counter restarts at 1.
enum InvoiceSequenceReset {
  daily,
  monthly,
  yearly;

  static InvoiceSequenceReset parse(String? text) {
    final value = (text ?? '').trim().toUpperCase();
    return switch (value) {
      'MONTHLY' || 'MONTH' => InvoiceSequenceReset.monthly,
      'YEARLY' || 'YEAR' => InvoiceSequenceReset.yearly,
      _ => InvoiceSequenceReset.daily,
    };
  }

  /// Prefix shared by every invoice number of the period containing [date],
  /// e.g. `INV-20261019-`, `INV-202610-` or `INV-2026-`.
  String prefixFor(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return switch (this) {
      InvoiceSequenceReset.daily => 'INV-$year$month$day-',
      InvoiceSequenceReset.monthly => 'INV-$year$month-',
      InvoiceSequenceReset.yearly => 'INV-$year-',
    };
  }

  String format(DateTime date, int sequence) =>
      '${prefixFor(date)}${sequence.toString().padLeft(4, '0')}';
}

/// Read from assets/config/invoice_sequence.txt (DAILY, MONTHLY or YEARLY).
final invoiceSequenceResetProvider = FutureProvider<InvoiceSequenceReset>((
  ref,
) async {
  try {
    return InvoiceSequenceReset.parse(
      await rootBundle.loadString(invoiceSequenceAssetPath),
    );
  } catch (_) {
    return InvoiceSequenceReset.daily;
  }
});
