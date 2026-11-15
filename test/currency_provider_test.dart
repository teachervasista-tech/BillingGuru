import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/settings/app_settings_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);

  test('defaults the currency to the text asset', () async {
    final configuredCode = (await rootBundle.loadString(
      'assets/config/currency.txt',
    )).trim();
    final container = await createTestContainer();
    addTearDown(container.dispose);

    expect(container.read(currencyProvider).code, configuredCode);
  });

  test('a currency saved in Settings overrides the asset default', () async {
    final container = await createTestContainer(
      storedSettings: {AppSettings.keyCurrency: 'USD'},
    );
    addTearDown(container.dispose);

    expect(container.read(currencyProvider).code, 'USD');
  });

  test('changing the currency persists and updates dependents', () async {
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await container
        .read(appSettingsProvider.notifier)
        .update((s) => s.copyWith(currencyCode: 'GBP'));

    expect(container.read(currencyProvider).code, 'GBP');
  });
}
