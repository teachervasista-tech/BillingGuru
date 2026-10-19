import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_navigation_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/sales/presentation/screens/sales_history_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/cart/presentation/screens/pos_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../core/config/app_features.dart';
import '../screens/placeholder_screen.dart';

String? featureRouteRedirect(String location) {
  final features = AppFeatures.instance;

  if (location.startsWith('/home') && !features.homeEnabled) {
    return '/dashboard';
  }

  if (location.startsWith('/products') && !features.productsEnabled) {
    return '/dashboard';
  }

  if ((location.startsWith('/pos') || location.startsWith('/checkout')) &&
      !features.posEnabled) {
    return '/dashboard';
  }

  if (location.startsWith('/customers') && !features.customersEnabled) {
    return '/dashboard';
  }

  if (location.startsWith('/sales') && !features.salesEnabled) {
    return '/dashboard';
  }

  if (location.startsWith('/reports') && !features.reportsEnabled) {
    return '/dashboard';
  }

  if (location.startsWith('/inventory') && !features.inventoryEnabled) {
    return '/dashboard';
  }

  if (location.startsWith('/settings') && !features.settingsEnabled) {
    return '/dashboard';
  }

  return null;
}

final GoRouter appRouter = GoRouter(
  // Home when enabled in features.json, otherwise the dashboard.
  initialLocation: AppFeatures.instance.homeEnabled ? '/home' : '/dashboard',
  redirect: (context, state) {
    return featureRouteRedirect(state.uri.path);
  },
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/home',
          name: 'home',
          redirect: (context, state) {
            return AppFeatures.instance.homeEnabled ? null : '/dashboard';
          },
          builder: (context, state) {
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) {
            final refreshKey = state.uri.queryParameters['refresh'];

            return DashboardScreen(key: ValueKey(refreshKey));
          },
        ),
        GoRoute(
          path: '/pos',
          name: 'pos',
          builder: (context, state) {
            return const PosScreen();
          },
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) {
            return const ProductsScreen();
          },
        ),
        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) {
            return const InventoryScreen();
          },
        ),
        GoRoute(
          path: '/sales',
          name: 'sales',
          builder: (context, state) {
            return const SalesHistoryScreen();
          },
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) {
            return const ReportsScreen();
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) {
            return const SettingsScreen();
          },
        ),
        GoRoute(
          path: '/customers',
          name: 'customers',
          builder: (context, state) {
            return const PlaceholderScreen(
              title: 'Customers',
              icon: Icons.people,
            );
          },
        ),
        GoRoute(
          path: '/checkout',
          name: 'Payment',
          builder: (context, state) {
            return const CheckoutScreen();
          },
        ),
      ],
    ),
  ],
);
