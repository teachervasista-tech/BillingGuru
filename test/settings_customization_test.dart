import 'package:billing_guru/app/navigation/app_navigation_shell.dart';
import 'package:billing_guru/core/config/app_features.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/printing/receipt_business_details_provider.dart';
import 'package:billing_guru/core/settings/app_settings_provider.dart';
import 'package:billing_guru/core/settings/settings_store.dart';
import 'package:billing_guru/features/settings/presentation/widgets/business_settings_tab.dart';
import 'package:billing_guru/features/settings/presentation/widgets/modules_settings_tab.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);

  Widget host(ProviderContainer container, Widget child) =>
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Scaffold(body: child)),
      );

  testWidgets('Business tab saves details, currency and persists them', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);
    final container = await createTestContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(host(container, const BusinessSettingsTab()));

    Future<void> fill(String key, String text) =>
        tester.enterText(find.byKey(Key(key)), text);
    await fill('businessNameField', 'Corner Store');
    await fill('businessAddressLine1Field', 'Main Street 1');
    await fill('businessAddressLine2Field', '');
    await fill('businessCityField', 'Springfield');
    await fill('businessStateField', 'IL');
    await fill('businessPostalCodeField', '62701');
    await fill('businessPhoneField', '555-0100');
    await fill('businessTaxIdField', 'TX-42');
    // The business fields push the regional settings below the fold.
    final currency = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(currency);
    await tester.pumpAndSettle();
    await tester.tap(currency);
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'USD ($)').last);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Monthly'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    final save = find.text('Save business settings');
    await tester.scrollUntilVisible(
      save,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(save);
    await tester.pumpAndSettle();

    final settings = container.read(appSettingsProvider);
    expect(settings.businessName, 'Corner Store');
    expect(settings.invoiceSequence, 'MONTHLY');
    expect(container.read(currencyProvider).code, 'USD');
    expect(
      await container.read(receiptBusinessDetailsProvider.future),
      'Corner Store\nMain Street 1\nSpringfield, IL 62701\n'
      'Phone: 555-0100\nTax ID: TX-42',
    );

    final store =
        container.read(settingsStoreProvider) as InMemorySettingsStore;
    expect(store.values[AppSettings.keyCurrency], 'USD');
    expect(store.values[BusinessDetails.keyCity], 'Springfield');
    expect(store.values[BusinessDetails.keyTaxId], 'TX-42');
  });

  testWidgets('disabling a module hides it from the navigation rail', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 2400);
    addTearDown(tester.view.reset);
    final container = await createTestContainer(user: testAdmin);
    addTearDown(container.dispose);
    await container
        .read(appSettingsProvider.notifier)
        .setFeature(AppFeatures.sales, true);

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        ShellRoute(
          builder: (_, _, child) => AppNavigationShell(child: child),
          routes: [
            GoRoute(
              path: '/settings',
              builder: (_, _) => const ModulesSettingsTab(),
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final rail = find.byType(NavigationRail);
    expect(
      find.descendant(of: rail, matching: find.text('Sales')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('module-sales')));
    await tester.pumpAndSettle();

    expect(container.read(appFeaturesProvider).salesEnabled, isFalse);
    expect(
      find.descendant(of: rail, matching: find.text('Sales')),
      findsNothing,
    );

    expect(
      find.descendant(of: rail, matching: find.text('Dashboard')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('module-dashboard')));
    await tester.pumpAndSettle();

    expect(container.read(appFeaturesProvider).dashboardEnabled, isFalse);
    expect(
      find.descendant(of: rail, matching: find.text('Dashboard')),
      findsNothing,
    );
  });
}
