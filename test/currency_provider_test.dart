import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads the currency code from the text asset', () async {
    SharedPreferences.setMockInitialValues({});
    final configuredCode = (await rootBundle.loadString(
      'assets/config/currency.txt',
    )).trim();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(currencyProvider.notifier).loadCurrencyFromAsset();

    expect(container.read(currencyProvider).code, configuredCode);
  });

  test(
    'asset currency takes precedence over a previously saved preference',
    () async {
      SharedPreferences.setMockInitialValues({'app_currency_code': 'USD'});
      final configuredCode = (await rootBundle.loadString(
        'assets/config/currency.txt',
      )).trim();
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(currencyProvider.notifier).loadCurrencyFromAsset();

      expect(container.read(currencyProvider).code, configuredCode);
    },
  );
}
