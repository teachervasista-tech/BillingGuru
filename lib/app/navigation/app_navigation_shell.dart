import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_features.dart';
import 'app_navigation_asset_icon.dart';

class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).uri.path;
    final selectedIndex = _selectedIndex(currentPath);

    return Scaffold(
      body: Row(
        children: [
          _AppNavigationRail(selectedIndex: selectedIndex),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(String path) {
    if (path == '/dashboard' || path == '/') {
      return 1;
    }

    if (path.startsWith('/pos')) {
      return 2;
    }

    if (path.startsWith('/products')) {
      return 3;
    }

    if (path.startsWith('/inventory')) {
      return 4;
    }

    if (path.startsWith('/sales')) {
      return 5;
    }

    if (path.startsWith('/reporting')) {
      return 6;
    }

    if (path.startsWith('/settings')) {
      return 7;
    }

    if (path.startsWith('/customers')) {
      return 8;
    }

    return 0;
  }
}

class _AppNavigationRail extends StatelessWidget {
  const _AppNavigationRail({required this.selectedIndex});

  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    final destinations = <NavigationRailDestination>[
      NavigationRailDestination(
        icon: const AppNavigationAssetIcon(
          assetPath: 'assets/images/home.png',
          size: 24,
        ),
        selectedIcon: const AppNavigationAssetIcon(
          assetPath: 'assets/images/home.png',
          size: 28,
        ),
        label: const Text('Home'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.point_of_sale_outlined),
        selectedIcon: Icon(Icons.point_of_sale),
        label: Text('PoS'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        selectedIcon: Icon(Icons.inventory_2),
        label: Text('Products'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.warehouse_outlined),
        selectedIcon: Icon(Icons.warehouse),
        label: Text('Inventory'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        selectedIcon: Icon(Icons.receipt_long),
        label: Text('Sales'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        selectedIcon: Icon(Icons.analytics),
        label: Text('Reporting'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.settings_outlined),
        selectedIcon: Icon(Icons.settings),
        label: Text('Settings'),
      ),
      if (AppFeatures.customersEnabled)
        const NavigationRailDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Customers'),
        ),
    ];

    return NavigationRail(
      selectedIndex: selectedIndex,
      labelType: NavigationRailLabelType.all,
      onDestinationSelected: (index) {
        _navigateToIndex(context, index);
      },
      destinations: destinations,
    );
  }

  void _navigateToIndex(BuildContext context, int index) {
    switch (index) {
      case 0:
        _refreshDashboard(context);
        return;

      case 1:
        context.go('/dashboard');
        return;

      case 2:
        context.go('/pos');
        return;

      case 3:
        context.go('/products');
        return;

      case 4:
        context.go('/inventory');
        return;

      case 5:
        context.go('/sales');
        return;

      case 6:
        context.go('/reporting');
        return;

      case 7:
        context.go('/settings');
        return;

      case 8:
        if (AppFeatures.customersEnabled) {
          context.go('/customers');
        }
        return;
    }
  }

  void _refreshDashboard(BuildContext context) {
    final router = GoRouter.of(context);

    router.go('/dashboard?refresh=${DateTime.now().millisecondsSinceEpoch}');
  }
}
