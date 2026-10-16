import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'currency.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

final currencyProvider = NotifierProvider<CurrencyNotifier, AppCurrency>(
  CurrencyNotifier.new,
);

class CurrencyNotifier extends Notifier<AppCurrency> {
  @override
  AppCurrency build() {
    return AppCurrency.eur;
  }

  Future<void> loadCurrencyFromAsset() async {
    final configuredCode = (await rootBundle.loadString(
      'assets/config/currency.txt',
    )).trim();

    state = AppCurrency.fromCode(configuredCode);
  }
}
