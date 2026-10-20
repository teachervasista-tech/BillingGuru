import 'package:flutter/material.dart';

class SideNavigationMenu extends StatelessWidget {
  const SideNavigationMenu({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 24, 16, 16),
          child: Row(
            children: [
              const Icon(Icons.point_of_sale, size: 32),
              const SizedBox(width: 12),
              Text(
                'POS Billing',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        const Divider(),
        NavigationDrawerDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: Text('Dashboard'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.point_of_sale_outlined),
          selectedIcon: Icon(Icons.point_of_sale),
          label: Text('Point of Sale'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: Text('Products'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.warehouse_outlined),
          selectedIcon: Icon(Icons.warehouse),
          label: Text('Inventory'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: Text('Sales'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.people_outline),
          selectedIcon: Icon(Icons.people),
          label: Text('Customers'),
        ),
        NavigationDrawerDestination(
          icon: Icon(Icons.bar_chart_outlined),
          selectedIcon: Icon(Icons.bar_chart),
          label: Text('Reports'),
        ),
        Divider(),
        NavigationDrawerDestination(
          icon: Icon(Icons.settings_outlined),
          selectedIcon: Icon(Icons.settings),
          label: Text('Settings'),
        ),
      ],
    );
  }
}
