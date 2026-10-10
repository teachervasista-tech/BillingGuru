import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_features.dart';

class AppNavigationShell extends StatelessWidget {
  const AppNavigationShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final items = _navigationItems(context);

    final currentPath = GoRouterState.of(context).uri.path;

    final selectedIndex = _selectedIndex(items, currentPath);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) {
              context.go(items[index].route);
            },
            destinations: items.map((item) {
              return NavigationRailDestination(
                icon: item.icon,
                selectedIcon: item.selectedIcon,
                label: Text(item.label),
              );
            }).toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _selectedIndex(List<_NavigationItem> items, String currentPath) {
    final index = items.indexWhere((item) {
      return item.matches(currentPath);
    });

    return index >= 0 ? index : 0;
  }

  List<_NavigationItem> _navigationItems(BuildContext context) {
    return [
      if (AppFeatures.instance.homeEnabled)
        _NavigationItem(
          label: 'Home',
          route: '/home',
          icon: Image.asset(
            'assets/images/navigation/home.png',
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          selectedIcon: Image.asset(
            'assets/images/navigation/home.png',
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        ),
      const _NavigationItem(
        label: 'Dashboard',
        route: '/dashboard',
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
      ),
      if (AppFeatures.instance.productsEnabled)
        const _NavigationItem(
          label: 'Products',
          route: '/products',
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
        ),
      if (AppFeatures.instance.posEnabled)
        const _NavigationItem(
          label: 'PoS',
          route: '/pos',
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          additionalPaths: ['/checkout'],
        ),
      if (AppFeatures.instance.customersEnabled)
        const _NavigationItem(
          label: 'Customers',
          route: '/customers',
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
        ),
      if (AppFeatures.instance.salesEnabled)
        const _NavigationItem(
          label: 'Sales',
          route: '/sales',
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
        ),
      if (AppFeatures.instance.reportsEnabled)
        const _NavigationItem(
          label: 'Reports',
          route: '/reports',
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
        ),
      if (AppFeatures.instance.inventoryEnabled)
        const _NavigationItem(
          label: 'Inventory',
          route: '/inventory',
          icon: Icon(Icons.warehouse_outlined),
          selectedIcon: Icon(Icons.warehouse),
        ),
      if (AppFeatures.instance.settingsEnabled)
        const _NavigationItem(
          label: 'Settings',
          route: '/settings',
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
        ),
    ];
  }
}

class _NavigationItem {
  const _NavigationItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    this.additionalPaths = const [],
  });

  final String label;
  final String route;
  final Widget icon;
  final Widget selectedIcon;
  final List<String> additionalPaths;

  bool matches(String currentPath) {
    if (currentPath == route || currentPath.startsWith('$route/')) {
      return true;
    }

    return additionalPaths.any((path) {
      return currentPath == path || currentPath.startsWith('$path/');
    });
  }
}
