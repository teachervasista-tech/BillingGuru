import 'package:intl/intl.dart';

import 'currency.dart';

class CurrencyFormatter {
  const CurrencyFormatter._();

  static String formatCents(int cents, {required AppCurrency currency}) {
    final amount = cents / 100;

    return NumberFormat.currency(
      locale: currency.locale,
      name: currency.code,
      symbol: currency.symbol,
      decimalDigits: currency.decimalDigits,
    ).format(amount);
  }

  static String formatCompactCents(int cents, {required AppCurrency currency}) {
    final amount = cents / 100;

    if (amount >= 1000) {
      return '${currency.symbol}'
          '${(amount / 1000).toStringAsFixed(1)}k';
    }

    return '${currency.symbol}'
        '${amount.toStringAsFixed(currency.decimalDigits)}';
  }
}
