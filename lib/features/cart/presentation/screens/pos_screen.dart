import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../products/presentation/widgets/product_category_pane.dart';
import '../../../products/presentation/widgets/product_search_field.dart';
import '../../../products/presentation/view_models/product_view_model.dart';
import '../../domain/cart_item.dart';
import '../view_models/cart_view_model.dart';
import '../widgets/cart_item_tile.dart';
import '../widgets/cart_summary.dart';

class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() {
    return _PosScreenState();
  }
}

class _PosScreenState extends ConsumerState<PosScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref
          .read(productViewModelProvider.notifier)
          .loadProducts(resetFilters: true);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Row(
              children: [
                const Expanded(flex: 7, child: _ProductsPanel()),
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(flex: 3, child: _CartPanel(cart: cart)),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}

class _ProductsPanel extends ConsumerWidget {
  const _ProductsPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productState = ref.watch(productViewModelProvider).asData?.value;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (productState != null) ...[
            ProductCategoryPane(productState: productState),
            const VerticalDivider(width: 1, thickness: 1),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Products',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const Expanded(child: ProductSearchField()),
              ],
            ),
          ),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text(
              'Current Cart',
              style: Theme.of(context).textTheme.headlineSmall,
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
