import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/config/app_features.dart';
import '../features/cart/presentation/screens/pos_screen.dart';
import '../features/checkout/presentation/screens/checkout_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../features/expenses/presentation/screens/expenses_screen.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/inventory/presentation/screens/inventory_screen.dart';
import '../features/products/presentation/screens/products_screen.dart';
import '../features/reports/presentation/screens/reports_screen.dart';
import '../features/sales/presentation/screens/sales_history_screen.dart';
import '../features/settings/presentation/screens/settings_screen.dart';
import 'screens/placeholder_screen.dart';

/// A top-level area of the app. Adding a module = adding one entry to
/// [appModules]; the router, route guard and navigation rail all read it.
class AppModule {
  const AppModule({
    required this.id,
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    required this.builder,
    this.featureKey,
    this.subRoutes = const [],
    this.showInNavigation = true,
  });

  final String id;
  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final Widget Function(BuildContext context, GoRouterState state) builder;

  /// [AppFeatures] key that switches the module on/off; null = always on.
  final String? featureKey;

  /// Extra routes owned by this module (guarded by the same feature key and
  /// highlighting the same navigation item).
  final List<GoRoute> subRoutes;
  final bool showInNavigation;

  bool isEnabled(AppFeatures features) =>
      featureKey == null || features.isEnabled(featureKey!);

  Iterable<String> get paths => [route, ...subRoutes.map((r) => r.path)];

  bool matches(String location) =>
      paths.any((path) => location == path || location.startsWith('$path/'));
}

Widget _navAsset(String name, double size) => Image.asset(
  'assets/images/navigation/$name.png',
  width: size,
  height: size,
  fit: BoxFit.contain,
);

/// Navigation order.
final List<AppModule> appModules = [
  AppModule(
    id: 'home',
    label: 'Home',
    route: '/home',
    featureKey: AppFeatures.home,
    icon: _navAsset('home', 24),
    selectedIcon: _navAsset('home', 28),
    builder: (_, _) => const HomeScreen(),
  ),
  AppModule(
    id: 'dashboard',
    label: 'Dashboard',
    route: '/dashboard',
    icon: const Icon(Icons.dashboard_outlined),
    selectedIcon: const Icon(Icons.dashboard),
    builder: (_, state) =>
        DashboardScreen(key: ValueKey(state.uri.queryParameters['refresh'])),
  ),
  AppModule(
    id: 'pos',
    label: 'PoS',
    route: '/pos',
    featureKey: AppFeatures.pos,
    icon: const Icon(Icons.point_of_sale_outlined),
    selectedIcon: const Icon(Icons.point_of_sale),
    builder: (_, _) => const PosScreen(),
    subRoutes: [
      GoRoute(
        path: '/checkout',
        name: 'Payment',
        builder: (_, _) => const CheckoutScreen(),
      ),
    ],
  ),
  AppModule(
    id: 'products',
    label: 'Products',
    route: '/products',
    featureKey: AppFeatures.products,
    icon: const Icon(Icons.inventory_2_outlined),
    selectedIcon: const Icon(Icons.inventory_2),
    builder: (_, _) => const ProductsScreen(),
  ),
  AppModule(
    id: 'customers',
    label: 'Customers',
    route: '/customers',
    featureKey: AppFeatures.customers,
    icon: const Icon(Icons.people_outline),
    selectedIcon: const Icon(Icons.people),
    builder: (_, _) =>
        const PlaceholderScreen(title: 'Customers', icon: Icons.people),
  ),
  AppModule(
    id: 'sales',
    label: 'Sales',
    route: '/sales',
    featureKey: AppFeatures.sales,
    icon: const Icon(Icons.receipt_long_outlined),
    selectedIcon: const Icon(Icons.receipt_long),
    builder: (_, _) => const SalesHistoryScreen(),
  ),
  AppModule(
    id: 'expenses',
    label: 'Expenses',
    route: '/expenses',
    featureKey: AppFeatures.expenses,
    icon: const Icon(Icons.account_balance_wallet_outlined),
    selectedIcon: const Icon(Icons.account_balance_wallet),
    builder: (_, _) => const ExpensesScreen(),
  ),
  AppModule(
    id: 'reports',
    label: 'Reports',
    route: '/reports',
    featureKey: AppFeatures.reports,
    icon: const Icon(Icons.analytics_outlined),
    selectedIcon: const Icon(Icons.analytics),
    builder: (_, _) => const ReportsScreen(),
  ),
  AppModule(
    id: 'inventory',
    label: 'Inventory',
    route: '/inventory',
    featureKey: AppFeatures.inventory,
    icon: const Icon(Icons.warehouse_outlined),
    selectedIcon: const Icon(Icons.warehouse),
    builder: (_, _) => const InventoryScreen(),
  ),
  AppModule(
    id: 'settings',
    label: 'Settings',
    route: '/settings',
    featureKey: AppFeatures.settings,
    icon: const Icon(Icons.settings_outlined),
    selectedIcon: const Icon(Icons.settings),
    builder: (_, _) => const SettingsScreen(),
  ),
];

const fallbackRoute = '/dashboard';

/// Redirects disabled modules (and their sub-routes) to the dashboard.
String? moduleRouteRedirect(String location, AppFeatures features) {
  for (final module in appModules) {
    if (module.matches(location)) {
      return module.isEnabled(features) ? null : fallbackRoute;
    }
  }
  return null;
}

String initialRoute(AppFeatures features) =>
    features.homeEnabled ? '/home' : fallbackRoute;
