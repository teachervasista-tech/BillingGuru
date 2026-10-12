import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/product_view_model.dart';
import 'product_list_item.dart';

class ProductSearchField extends ConsumerWidget {
  const ProductSearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            decoration: InputDecoration(
              labelText: 'Search product or barcode',
              hintText: 'Type Coffee, Tea, or a barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  ref.read(productViewModelProvider.notifier).clearSearch();
                },
              ),
            ),
            onChanged: (value) {
              ref
                  .read(productViewModelProvider.notifier)
                  .search(value, includeCatalogMeta: false);
            },
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
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
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
