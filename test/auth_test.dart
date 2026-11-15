import 'package:billing_guru/app/app.dart';
import 'package:billing_guru/app/modules.dart';
import 'package:billing_guru/core/config/app_features.dart';
import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/features/auth/data/user_service.dart';
import 'package:billing_guru/features/auth/presentation/auth_providers.dart';
import 'package:billing_guru/features/checkout/data/repositories/checkout_repository.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/checkout/domain/sale.dart';
import 'package:billing_guru/features/sales/data/services/sales_local_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('password hashes are salted and verify only the right password', () {
    final a = testHasher.hash('secret1');
    final b = testHasher.hash('secret1');
    expect(a, isNot(b));
    expect(testHasher.verify('secret1', a), isTrue);
    expect(testHasher.verify('secret2', a), isFalse);
    expect(testHasher.verify('secret1', 'garbage'), isFalse);
  });

  group('UserService', () {
    late AppDatabase database;
    late UserService users;

    setUp(() {
      database = createTestDatabase();
      users = UserService(database: database, hasher: testHasher);
    });
    tearDown(() => database.close());

    Future<AppUser> admin() => users.createUser(
      username: 'admin',
      displayName: 'Owner',
      password: 'admin123',
      role: UserRole.admin,
    );

    test('creates, authenticates and rejects bad credentials', () async {
      expect(await users.hasUsers(), isFalse);
      await admin();
      expect(await users.hasUsers(), isTrue);

      final signedIn = await users.authenticate('ADMIN', 'admin123');
      expect(signedIn.displayName, 'Owner');
      expect(signedIn.isAdmin, isTrue);
      expect(
        () => users.authenticate('admin', 'wrong'),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => users.authenticate('nobody', 'admin123'),
        throwsA(isA<AuthException>()),
      );
    });

    test('usernames are unique and passwords have a minimum length', () async {
      await admin();
      expect(
        () => users.createUser(
          username: 'Admin',
          displayName: '',
          password: 'whatever1',
          role: UserRole.seller,
        ),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => users.createUser(
          username: 'sam',
          displayName: '',
          password: '123',
          role: UserRole.seller,
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('disabled sellers cannot sign in', () async {
      await admin();
      final seller = await users.createUser(
        username: 'sam',
        displayName: 'Sam',
        password: 'seller1',
        role: UserRole.seller,
      );
      await users.updateUser(seller.id, isActive: false);
      await expectLater(
        users.authenticate('sam', 'seller1'),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('disabled'),
          ),
        ),
      );
    });

    test('the last active admin cannot be demoted or disabled', () async {
      final owner = await admin();
      expect(
        () => users.updateUser(owner.id, role: UserRole.seller),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => users.updateUser(owner.id, isActive: false),
        throwsA(isA<AuthException>()),
      );

      final second = await users.createUser(
        username: 'boss2',
        displayName: '',
        password: 'admin456',
        role: UserRole.admin,
      );
      await users.updateUser(owner.id, role: UserRole.seller);
      expect((await users.authenticate('admin', 'admin123')).isAdmin, isFalse);
      expect(
        () => users.updateUser(second.id, isActive: false),
        throwsA(isA<AuthException>()),
      );
    });

    test('change own password requires the current one', () async {
      final owner = await admin();
      expect(
        () => users.changeOwnPassword(owner, 'nope', 'newpass1'),
        throwsA(isA<AuthException>()),
      );
      await users.changeOwnPassword(owner, 'admin123', 'newpass1');
      expect((await users.authenticate('admin', 'newpass1')).id, owner.id);
    });

    test('sales record who made them', () async {
      final seller = await users.createUser(
        username: 'sam',
        displayName: 'Sam Seller',
        password: 'seller1',
        role: UserRole.seller,
      );
      await CheckoutRepository(database: database).saveSale(
        Sale(
          id: 's1',
          invoiceNumber: 'INV-1',
          items: const [],
          subtotalCents: 0,
          discountCents: 0,
          taxCents: 0,
          totalCents: 0,
          paymentMethod: PaymentMethod.cash,
          createdAt: DateTime(2026, 11, 15),
          syncStatus: 'pending',
          userId: seller.id,
        ),
      );
      final sale = (await SalesLocalService(database: database)
          .getSaleById('s1'))!;
      expect(sale.sellerName, 'Sam Seller');
    });
  });

  group('permissions', () {
    const features = AppFeatures();

    test('sellers are kept out of settings, expenses and reports', () {
      for (final route in ['/settings', '/expenses', '/reports']) {
        expect(
          moduleRouteRedirect(route, features, testSeller),
          fallbackRoute,
          reason: route,
        );
        expect(moduleRouteRedirect(route, features, testAdmin), isNull);
      }
      for (final route in ['/pos', '/sales', '/products', '/customers']) {
        expect(moduleRouteRedirect(route, features, testSeller), isNull);
      }
    });

    test('role permissions', () {
      expect(testAdmin.can(Permission.manageUsers), isTrue);
      expect(
        Permission.values.where(testSeller.can),
        isEmpty,
        reason: 'sellers only have the unrestricted basics',
      );
    });
  });

  testWidgets('first start: create admin, then a seller sees fewer modules', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1600, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    rootBundle.clear();

    final database = createTestDatabase();
    final container = await createTestContainer(database: database);
    addTearDown(() async {
      container.dispose();
      await database.close();
    });

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BillingGuru(),
      ),
    );
    await tester.pumpAndSettle();

    // No accounts yet: setup screen.
    expect(find.text('Create the admin account'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('setupName')), 'Owner');
    await tester.enterText(find.byKey(const Key('setupPassword')), 'admin123');
    await tester.enterText(find.byKey(const Key('setupConfirm')), 'admin123');
    await tester.tap(find.byKey(const Key('setupButton')));
    await tester.pumpAndSettle();

    final rail = find.byType(NavigationRail);
    expect(rail, findsOneWidget);
    expect(
      find.descendant(of: rail, matching: find.text('Settings')),
      findsOneWidget,
    );

    // Admin creates a seller (service call; the dialog is covered above).
    await container
        .read(userServiceProvider)
        .createUser(
          username: 'sam',
          displayName: 'Sam',
          password: 'seller1',
          role: UserRole.seller,
        );

    // Sign out -> login screen -> sign in as the seller.
    container.read(authProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.text('Sign in'), findsWidgets);

    await tester.enterText(find.byKey(const Key('loginUsername')), 'sam');
    await tester.enterText(find.byKey(const Key('loginPassword')), 'wrong!!');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect username or password.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('loginPassword')), 'seller1');
    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    final sellerRail = find.byType(NavigationRail);
    for (final hidden in ['Settings', 'Expenses', 'Reports']) {
      expect(
        find.descendant(of: sellerRail, matching: find.text(hidden)),
        findsNothing,
        reason: hidden,
      );
    }
    expect(
      find.descendant(of: sellerRail, matching: find.text('Sales')),
      findsOneWidget,
    );
  });
}
