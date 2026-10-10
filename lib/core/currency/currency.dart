class AppCurrency {
  const AppCurrency({
    required this.code,
    required this.symbol,
    required this.locale,
    required this.decimalDigits,
  });

  final String code;
  final String symbol;
  final String locale;
  final int decimalDigits;

  String get displayName {
    return '$code ($symbol)';
  }

  static const AppCurrency eur = AppCurrency(
    code: 'EUR',
    symbol: '€',
    locale: 'de_DE',
    decimalDigits: 2,
  );

  static const AppCurrency usd = AppCurrency(
    code: 'USD',
    symbol: r'$',
    locale: 'en_US',
    decimalDigits: 2,
  );

  static const AppCurrency gbp = AppCurrency(
    code: 'GBP',
    symbol: '£',
    locale: 'en_GB',
    decimalDigits: 2,
  );

  static const AppCurrency inr = AppCurrency(
    code: 'INR',
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
  );

  static const List<AppCurrency> supported = [eur, usd, gbp, inr];

  static AppCurrency fromCode(String? code) {
    if (code == null || code.isEmpty) {
      return eur;
    }

    for (final currency in supported) {
      if (currency.code == code) {
        return currency;
      }
    }

    return eur;
  }
}
