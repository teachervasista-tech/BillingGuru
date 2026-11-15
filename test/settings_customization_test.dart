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

    await tester.enterText(
      find.byKey(const Key('businessDetailsField')),
      'Corner Store\nMain Street 1',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'USD ($)').last);
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
      'Corner Store\nMain Street 1',
    );

    final store =
        container.read(settingsStoreProvider) as InMemorySettingsStore;
    expect(store.values[AppSettings.keyCurrency], 'USD');
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
  });
}
