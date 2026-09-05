import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/side_navigation_rail.dart';
import '../../../products/presentation/widgets/product_search_field.dart';
import '../../domain/cart_item.dart';
import '../view_models/cart_view_model.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary.dart';

class PosScreen extends ConsumerWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            tooltip: 'Sales history',
            icon: const Icon(Icons.receipt_long),
            onPressed: () => context.go('/sales'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: Row(
        children: [
          SideNavigationRail(
            selectedIndex: 1,
            onDestinationSelected: (index) {
              _navigateToDestination(context, index);
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                const Expanded(flex: 5, child: _ProductsPanel()),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(flex: 5, child: _CartPanel(cart: cart)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDestination(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/pos');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/inventory');
        break;
      case 4:
        context.go('/sales');
        break;
      case 5:
        context.go('/customers');
        break;
      case 6:
        context.go('/reports');
        break;
      case 7:
        context.go('/settings');
        break;
    }
  }
}

class _ProductsPanel extends StatelessWidget {
  const _ProductsPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Products',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: ProductSearchField()),
        ],
      ),
    );
  }
}

class _CartPanel extends StatelessWidget {
  const _CartPanel({required this.cart});

  final List<CartItem> cart;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Current Cart',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: cart.isEmpty
                ? const Center(child: Text('The cart is empty'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: cart.length,
                    itemBuilder: (context, index) {
                      return CartItemTile(item: cart[index]);
                    },
                  ),
          ),
          const CartSummary(),
        ],
      ),
    );
  }
}
