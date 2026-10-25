import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/view_models/cart_view_model.dart';

import '../view_models/product_view_model.dart';
import 'product_list_item.dart';

class ProductSearchField extends ConsumerStatefulWidget {
  const ProductSearchField({super.key});

  @override
  ConsumerState<ProductSearchField> createState() => _ProductSearchFieldState();
}

class _ProductSearchFieldState extends ConsumerState<ProductSearchField> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearSearch() {
    _searchController.clear();

    ref.read(productViewModelProvider.notifier).clearSearch();

    FocusScope.of(context).unfocus();
  }

  Future<void> _handleSubmittedValue(String value) async {
    final barcode = value.trim();

    if (barcode.isEmpty) {
      return;
    }

    final product = await ref
        .read(productViewModelProvider.notifier)
        .findProductByBarcode(barcode);

    if (!mounted) {
      return;
    }

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Product not found. Please add the product first, then scan the barcode again.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(cartProvider.notifier).addProduct(product);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart.'),
        backgroundColor: Colors.green,
      ),
    );

    _clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(
      productViewModelProvider.select(
        (value) => value.whenData((state) => state.products),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search product or barcode',
              hintText: 'Type Coffee, Tea, or a barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: ValueListenableBuilder<TextEditingValue>(
                valueListenable: _searchController,
                builder: (context, value, _) {
                  if (value.text.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return IconButton(
                    tooltip: 'Clear search',
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  );
                },
              ),
            ),
            onChanged: (value) {
              ref
                  .read(productViewModelProvider.notifier)
                  .search(value, includeCatalogMeta: false);
            },
            onSubmitted: _handleSubmittedValue,
          ),
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Unable to load products',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('$error', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref
                              .read(productViewModelProvider.notifier)
                              .loadProducts(includeCatalogMeta: false);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            },
            data: (products) {
              if (products.isEmpty) {
                return const Center(child: Text('No products found'));
              }

              return RefreshIndicator(
                onRefresh: () {
                  return ref
                      .read(productViewModelProvider.notifier)
                      .loadProducts(includeCatalogMeta: false);
                },
                child: ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return ProductListItem(
                      product: products[index],
                      showAddToCart: true,
                      showManagementActions: false,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
