import 'package:billing_guru/core/tax/tax_rate_provider.dart';
import 'package:billing_guru/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses 19 percent when no default tax rate has been saved', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(defaultTaxRateProvider.notifier).loadSavedTaxRate();

    expect(container.read(defaultTaxRateProvider), 19);
  });

  test('saves and reloads the default tax rate', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    await container.read(defaultTaxRateProvider.notifier).loadSavedTaxRate();
    await container.read(defaultTaxRateProvider.notifier).setDefaultTaxRate(18);
    container.dispose();

    final reloadedContainer = ProviderContainer();
    addTearDown(reloadedContainer.dispose);
    await reloadedContainer
        .read(defaultTaxRateProvider.notifier)
        .loadSavedTaxRate();

    expect(reloadedContainer.read(defaultTaxRateProvider), 18);
  });

  testWidgets('Settings saves the default tax percentage', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(defaultTaxRateProvider.notifier).loadSavedTaxRate();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, '12');
    await tester.tap(find.text('Save tax rate'));
    await tester.pumpAndSettle();

    expect(container.read(defaultTaxRateProvider), 12);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('app_default_tax_rate'), 12);
  });
}
