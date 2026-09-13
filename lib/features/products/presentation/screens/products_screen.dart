import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/side_navigation_rail.dart';
import '../../../../app/widgets/copyright_banner.dart';
import '../view_models/product_view_model.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/product_list_item.dart';
import '../widgets/inactive_product_list_item.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  Future<void> _showAddProductDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final added = await showDialog<bool>(
      context: context,
      builder: (context) {
        return const ProductFormDialog();
      },
    );

    if (added == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product added successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(productViewModelProvider.notifier).loadProducts();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          SideNavigationRail(
            selectedIndex: 2,
            onDestinationSelected: (index) {
              _navigateToDestination(context, index);
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Product catalog',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: () {
                          _showAddProductDialog(context, ref);
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add product'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const _ProductSearchInput(),
                  const SizedBox(height: 16),
                  Expanded(
                    child: productsAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Unable to load products: $error'),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  ref
                                      .read(productViewModelProvider.notifier)
                                      .loadProducts();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                      data: (productState) {
                        final visibleProducts = productState.visibleProducts;

                        if (visibleProducts.isEmpty) {
                          return Center(
                            child: Text(
                              productState.showInactive
                                  ? 'No inactive products found'
                                  : 'No active products found',
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: visibleProducts.length,
                          itemBuilder: (context, index) {
                            final product = visibleProducts[index];

                            if (productState.showInactive) {
                              return InactiveProductListItem(product: product);
                            }

                            return ProductListItem(
                              product: product,
                              showAddToCart: false,
                              showManagementActions: true,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CopyrightBanner(),
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

class _ProductSearchInput extends ConsumerStatefulWidget {
  const _ProductSearchInput();

  @override
  ConsumerState<_ProductSearchInput> createState() {
    return _ProductSearchInputState();
  }
}

class _ProductSearchInputState extends ConsumerState<_ProductSearchInput> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: InputDecoration(
        labelText: 'Search products',
        hintText: 'Search by name or barcode',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          tooltip: 'Clear search',
          icon: const Icon(Icons.clear),
          onPressed: () {
            _controller.clear();

            ref.read(productViewModelProvider.notifier).clearSearch();
          },
        ),
      ),
      onChanged: (value) {
        ref.read(productViewModelProvider.notifier).search(value);
      },
    );
  }
}
