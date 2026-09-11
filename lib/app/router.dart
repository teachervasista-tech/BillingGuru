import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/cart/presentation/screens/pos_screen.dart';
import '../features/checkout/presentation/screens/checkout_screen.dart';
import '../features/sales/presentation/screens/sales_history_screen.dart';
import '../features/products/presentation/screens/products_screen.dart';
import '../features/dashboard/presentation/screens/dashboard_screen.dart';

import 'screens/placeholder_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/pos',
  routes: [
    GoRoute(
      path: '/dashboard',
      builder: (context, state) {
        return const DashboardScreen();
      },
    ),
    GoRoute(path: '/pos', builder: (context, state) => const PosScreen()),
    GoRoute(
      path: '/products',
      builder: (context, state) => const ProductsScreen(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Inventory', icon: Icons.warehouse),
    ),
    GoRoute(
      path: '/sales',
      builder: (context, state) {
        return const SalesHistoryScreen();
      },
    ),
    GoRoute(
      path: '/customers',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Customers', icon: Icons.people),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Reports', icon: Icons.bar_chart),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Settings', icon: Icons.settings),
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
  ],
);
