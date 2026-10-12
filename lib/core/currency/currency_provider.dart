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
  static const String _currencyKey = 'app_currency_code';

  @override
  AppCurrency build() {
    return AppCurrency.eur;
  }

  Future<void> loadSavedCurrency() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final configuredCode = (await rootBundle.loadString(
      'assets/config/currency.txt',
    )).trim();

    final savedCode = prefs.getString(_currencyKey)?.trim();

    state = AppCurrency.fromCode(
      savedCode == null || savedCode.isEmpty ? configuredCode : savedCode,
    );
  }

  Future<void> selectCurrency(AppCurrency currency) async {
    state = currency;

    final prefs = await ref.read(sharedPreferencesProvider.future);

    await prefs.setString(_currencyKey, currency.code);
  }
}
