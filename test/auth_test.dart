import 'package:billing_guru/app/app.dart';
import 'package:billing_guru/app/modules.dart';
import 'package:billing_guru/core/config/app_features.dart';
import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/database/migrations.dart';
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
      expect(await users.hasUsers(), isTrue, reason: 'installer is built in');
      await admin();

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

  group('installer account', () {
    late AppDatabase database;
    late UserService users;

    setUp(() {
      database = createTestDatabase();
      users = UserService(database: database, hasher: testHasher);
    });
    tearDown(() => database.close());

    test('is created with the database and must change its password', () async {
      expect(await users.isFirstUse(), isTrue);
      final installer = await users.authenticate(
        installerUsername,
        installerDefaultPassword,
      );
      expect(installer.isInstaller, isTrue);
      expect(installer.mustChangePassword, isTrue);

      await users.setPassword(installer.id, 'setup-pass');
      expect(await users.isFirstUse(), isFalse);
      final again = await users.authenticate(installerUsername, 'setup-pass');
      expect(again.mustChangePassword, isFalse);
    });

    test('is hidden from admins and cannot be changed or recreated', () async {
      final installer = await users.authenticate(
        installerUsername,
        installerDefaultPassword,
      );
      expect((await users.getUsers()).where((u) => u.isInstaller), isEmpty);
      expect(
        (await users.getUsers(includeInstaller: true)).single.isInstaller,
        isTrue,
      );
      expect(
        () => users.updateUser(installer.id, isActive: false),
        throwsA(isA<AuthException>()),
      );
      expect(
        () => users.createUser(
          username: 'installer2',
          displayName: '',
          password: 'whatever1',
          role: UserRole.installer,
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('permissions', () {
    const features = AppFeatures();

    test('installer: only Settings, landing there', () {
      expect(landingRoute(features, testInstaller), '/settings');
      for (final route in [
        '/home',
        '/pos',
        '/sales',
        '/expenses',
        '/reports',
      ]) {
        expect(
          moduleRouteRedirect(route, features, testInstaller),
          '/settings',
          reason: route,
        );
      }
      expect(moduleRouteRedirect('/settings', features, testInstaller), isNull);
    });

    test('admin: everything; seller: no settings, expenses or reports', () {
      for (final route in ['/settings', '/expenses', '/reports', '/pos']) {
        expect(moduleRouteRedirect(route, features, testAdmin), isNull);
      }
      for (final route in ['/settings', '/expenses', '/reports']) {
        expect(
          moduleRouteRedirect(route, features, testSeller),
          '/home',
          reason: route,
        );
      }
      for (final route in ['/pos', '/sales', '/products', '/customers']) {
        expect(moduleRouteRedirect(route, features, testSeller), isNull);
      }
    });

    test('settings tabs by role', () {
      expect(testInstaller.can(Permission.configureSystem), isTrue);
      expect(testInstaller.can(Permission.manageUsers), isTrue);
      expect(testInstaller.can(Permission.manageCategories), isFalse);
      expect(testAdmin.can(Permission.configureSystem), isFalse);
      expect(testAdmin.can(Permission.manageTax), isTrue);
      expect(testInstaller.can(Permission.manageTax), isTrue);
      expect(testAdmin.can(Permission.manageUsers), isTrue);
      expect(testAdmin.can(Permission.manageCategories), isTrue);
      expect(testSeller.can(Permission.openSettings), isFalse);
      expect(testSeller.role.permissions, [Permission.operate]);
    });
  });

  testWidgets('installer sets up; admin and seller see their own areas', (
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

    Future<void> signIn(String username, String password) async {
      await tester.enterText(find.byKey(const Key('loginUsername')), username);
      await tester.enterText(find.byKey(const Key('loginPassword')), password);
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();
    }

    Finder tab(String label) =>
        find.descendant(of: find.byType(TabBar), matching: find.text(label));

    // First use: hint, then the installer must replace the default password.
    expect(find.textContaining('First time?'), findsOneWidget);
    await signIn(installerUsername, installerDefaultPassword);
    expect(find.text('Set a new password'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('newPassword')), 'setup-pass');
    await tester.enterText(
      find.byKey(const Key('confirmPassword')),
      'setup-pass',
    );
    await tester.tap(find.byKey(const Key('savePasswordButton')));
    await tester.pumpAndSettle();

    // Installer lands on Settings: system tabs and Users only.
    for (final label in ['Business', 'Printer', 'Modules', 'Data', 'Users']) {
      expect(tab(label), findsOneWidget, reason: label);
    }
    expect(tab('Product categories'), findsNothing);
    expect(find.text('PoS'), findsNothing);
    expect(find.byKey(const Key('userMenu')), findsOneWidget);

    final service = container.read(userServiceProvider);
    await service.createUser(
      username: 'owner',
      displayName: 'Owner',
      password: 'owner123',
      role: UserRole.admin,
    );
    await service.createUser(
      username: 'sam',
      displayName: 'Sam',
      password: 'seller1',
      role: UserRole.seller,
    );

    // Admin: Users and categories in Settings, no system tabs.
    container.read(authProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.textContaining('First time?'), findsNothing);
    await signIn('owner', 'owner123');
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Settings'),
      ),
    );
    await tester.pumpAndSettle();
    expect(tab('Users'), findsOneWidget);
    expect(tab('Tax'), findsOneWidget);
    expect(tab('Product categories'), findsOneWidget);
    expect(tab('Business'), findsNothing);
    expect(tab('Data'), findsNothing);

    // Seller: no Settings at all.
    container.read(authProvider.notifier).logout();
    await tester.pumpAndSettle();
    await signIn('sam', 'seller1');
    final rail = find.byType(NavigationRail);
    for (final hidden in ['Settings', 'Expenses', 'Reports']) {
      expect(
        find.descendant(of: rail, matching: find.text(hidden)),
        findsNothing,
        reason: hidden,
      );
    }
    expect(
      find.descendant(of: rail, matching: find.text('Sales')),
      findsOneWidget,
    );
  });
}
