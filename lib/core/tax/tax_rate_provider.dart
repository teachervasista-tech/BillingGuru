import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency/currency_provider.dart';

final defaultTaxRateProvider = NotifierProvider<DefaultTaxRateNotifier, int>(
  DefaultTaxRateNotifier.new,
);

class DefaultTaxRateNotifier extends Notifier<int> {
  static const _preferenceKey = 'app_default_tax_rate';
  static const _fallbackRate = 19;

  @override
  int build() {
    return _fallbackRate;
  }

  Future<void> loadSavedTaxRate() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final savedRate = prefs.getInt(_preferenceKey);

    state = savedRate != null && savedRate >= 0 && savedRate <= 100
        ? savedRate
        : _fallbackRate;
  }

  Future<void> setDefaultTaxRate(int rate) async {
    if (rate < 0 || rate > 100) {
      throw ArgumentError.value(rate, 'rate', 'Must be between 0 and 100.');
    }

    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setInt(_preferenceKey, rate);
    state = rate;
  }
}
