import 'package:billing_guru/core/config/app_features.dart';
import 'package:flutter/material.dart';

class SideNavigationRail extends StatelessWidget {
  const SideNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      extended: true,
      minExtendedWidth: 220,
      backgroundColor: Theme.of(context).colorScheme.surface,
      leading: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Row(
          children: [
            Icon(
              Icons.point_of_sale,
              size: 32,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'POS Billing',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      destinations: [
        const NavigationRailDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: Text('Point of Sale'),
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
        if (AppFeatures.instance.settingsEnabled)
          const NavigationRailDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: Text('Customers'),
          ),
        const NavigationRailDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Reports'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
