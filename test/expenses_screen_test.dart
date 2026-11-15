import 'package:billing_guru/features/expenses/presentation/screens/expenses_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(rootBundle.clear);

  testWidgets('adding an expense lists it and updates the total', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final database = createTestDatabase();
    final container = await createTestContainer(database: database);
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ExpensesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('No expenses for this period.'), findsOneWidget);

    await tester.tap(find.text('Add expense'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('expenseCategoryField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Utilities').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('expenseAmountField')),
      '45.50',
    );
    await tester.enterText(
      find.byKey(const Key('expenseVendorField')),
      'Power Co',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Power Co'), findsOneWidget);
    expect(find.text('1 expense'), findsOneWidget);
    final total = tester.widget<Text>(find.byKey(const Key('expensesTotal')));
    expect(total.data, contains('45'));
  });
}
