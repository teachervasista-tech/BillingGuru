import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/product_view_model.dart';
import 'product_list_item.dart';

class ProductSearchField extends ConsumerWidget {
  const ProductSearchField({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productViewModelProvider);

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
              ref.read(productViewModelProvider.notifier).search(value);
            },
          ),
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text(
                'Unable to load products:\n$error',
                textAlign: TextAlign.center,
              ),
            ),
            data: (productState) {
              if (productState.products.isEmpty) {
                return const Center(child: Text('No products found'));
              }

              return ListView.builder(
                padding: const EdgeInsets.only(left: 8, right: 8, bottom: 16),
                itemCount: productState.products.length,
                itemBuilder: (context, index) {
                  return ProductListItem(product: productState.products[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
