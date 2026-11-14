import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/printing/receipt_paper_size.dart';
import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:billing_guru/core/tax/tax_rate_provider.dart';
import 'package:billing_guru/features/settings/presentation/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // rootBundle caches each asset's Future in the zone of the test that first
  // loaded it. A later test awaiting that cached Future never resumes, because
  // its completion is scheduled in the earlier test's finished zone. Clearing
  // the cache makes every test load assets in its own zone.
  setUp(rootBundle.clear);

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
    expect(find.text('Configured currency'), findsNothing);
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
    expect(find.textContaining('[Street Address]'), findsNothing);

    await tester.tap(find.byType(DropdownButtonFormField<ReceiptPaperSize>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2" (58 mm)').last);
    await tester.pumpAndSettle();
    expect(container.read(receiptPaperSizeProvider), ReceiptPaperSize.twoInch);

    await tester.tap(find.byType(DropdownButtonFormField<ReceiptTemplate>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Detailed').last);
    await tester.pumpAndSettle();
    expect(container.read(receiptTemplateProvider), ReceiptTemplate.detailed);

    await tester.tap(find.text('Preview receipt'));
    await tester.pumpAndSettle();

    expect(find.text('Detailed receipt preview'), findsOneWidget);
    // On 2" paper the name wraps inside its column; qty, price and total
    // stay on the first line of the name.
    expect(
      find.textContaining(RegExp(r'Coffee +2 +12\.50 +25\.00\n\s*beans')),
      findsOneWidget,
    );
    expect(find.textContaining('Invoice:'), findsOneWidget);
    expect(find.textContaining('Subtotal'), findsOneWidget);
    expect(find.textContaining('TOTAL'), findsOneWidget);
  });
}
