import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../navigation/app_navigation_shell.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/products/presentation/screens/products_screen.dart';
import '../../features/sales/presentation/screens/sales_history_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/cart/presentation/screens/pos_screen.dart';
import '../../features/checkout/presentation/screens/checkout_screen.dart';
import '../screens/placeholder_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return AppNavigationShell(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          name: 'Home',
          builder: (context, state) {
            return const DashboardScreen();
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
          path: '/reporting',
          name: 'reporting',
          builder: (context, state) {
            return const PlaceholderScreen(
              title: 'Reporting',
              icon: Icons.bar_chart,
            );
          },
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) {
            return const PlaceholderScreen(
              title: 'Settings',
              icon: Icons.people,
            );
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
