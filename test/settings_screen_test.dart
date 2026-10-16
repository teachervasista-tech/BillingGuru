import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:billing_guru/core/tax/tax_rate_provider.dart';
import 'package:billing_guru/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Tax & Currency tab displays the asset currency', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(currencyProvider.notifier).loadCurrencyFromAsset();
    await container.read(defaultTaxRateProvider.notifier).loadSavedTaxRate();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    expect(find.text('Tax percentage'), findsOneWidget);
    expect(find.text('Configured currency'), findsOneWidget);
    expect(find.text('INR (₹)'), findsOneWidget);
  });

  testWidgets('Printer tab selects a template and previews its receipt', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await container.read(currencyProvider.notifier).loadCurrencyFromAsset();
    await container.read(defaultTaxRateProvider.notifier).loadSavedTaxRate();
    await container.read(receiptTemplateProvider.notifier).loadSavedTemplate();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );

    await tester.tap(find.text('Printer'));
    await tester.pumpAndSettle();
    expect(find.text('Bill receipt template'), findsOneWidget);
    expect(find.textContaining('[Street Address]'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<ReceiptTemplate>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detailed').last);
    await tester.pumpAndSettle();
    expect(container.read(receiptTemplateProvider), ReceiptTemplate.detailed);

    await tester.tap(find.text('Preview receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Detailed receipt preview'), findsOneWidget);
    expect(find.textContaining('Coffee beans'), findsOneWidget);
    expect(find.textContaining('Date:'), findsOneWidget);
    expect(find.textContaining('Time:'), findsOneWidget);
    expect(find.textContaining('2 x'), findsOneWidget);
    expect(find.textContaining('Subtotal:'), findsOneWidget);
    expect(find.textContaining('Tax:'), findsOneWidget);
    expect(find.textContaining('TOTAL:'), findsOneWidget);
  });
}
