import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../view_models/product_view_model.dart';
import '../widgets/inactive_product_list_item.dart';
import '../widgets/product_form_dialog.dart';
import '../widgets/product_list_item.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() {
    return _ProductsScreenState();
  }
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  late final TextEditingController _searchController;

  bool _showInactive = false;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController();

    Future.microtask(() {
      ref.read(productViewModelProvider.notifier).loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(context, productsAsync.asData?.value),
                  const SizedBox(height: 16),
                  _buildSearchAndFilterRow(ref, productsAsync.asData?.value),
                  const SizedBox(height: 16),
                  Expanded(
                    child: _buildProductBody(context, ref, productsAsync),
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

  Widget _buildHeader(BuildContext context, ProductState? productState) {
    final productCount = productState == null
        ? null
        : (_showInactive
              ? productState.inactiveProducts.length
              : productState.products.length);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Product catalog',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              if (productCount != null)
                Text(
                  '$productCount products',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        FilledButton.icon(
          onPressed: () {
            _showAddProductDialog(context);
          },
          icon: const Icon(Icons.add),
          label: const Text('Add product'),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterRow(WidgetRef ref, ProductState? productState) {
    final categories = productState?.categories ?? const <String>[];
    final selectedCategory = productState?.selectedCategory;
    final categoryValue = categories.contains(selectedCategory)
        ? selectedCategory!
        : '';
    final totalProducts =
        productState?.categoryCounts.values.fold<int>(
          0,
          (sum, count) => sum + count,
        ) ??
        0;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search products',
              hintText: 'Search by name or barcode',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                tooltip: 'Clear search',
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();

                  ref.read(productViewModelProvider.notifier).clearSearch();
                },
              ),
            ),
            onChanged: (value) {
              ref.read(productViewModelProvider.notifier).search(value);
            },
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 240,
          child: DropdownButtonFormField<String>(
            key: ValueKey(categoryValue),
            initialValue: categoryValue,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: '',
                child: Text('All categories ($totalProducts)'),
              ),
              ...categories.map((category) {
                final count = productState?.categoryCounts[category] ?? 0;
                return DropdownMenuItem(
                  value: category,
                  child: Text('$category ($count)'),
                );
              }),
            ],
            onChanged: categories.isEmpty
                ? null
                : (value) {
                    ref
                        .read(productViewModelProvider.notifier)
                        .selectCategory(
                          value == null || value.isEmpty ? null : value,
                        );
                  },
          ),
        ),
        const SizedBox(width: 16),
        FilterChip(
          label: const Text('Inactive products'),
          selected: _showInactive,
          onSelected: (value) {
            setState(() {
              _showInactive = value;
            });

            ref.read(productViewModelProvider.notifier).setShowInactive(value);
          },
        ),
      ],
    );
  }

  Widget _buildProductBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<ProductState> productsAsync,
  ) {
    return productsAsync.when(
      loading: () {
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stackTrace) {
        return _ErrorView(
          message: 'Unable to load products:\n$error',
          onRetry: () {
            ref.read(productViewModelProvider.notifier).loadProducts();
          },
        );
      },
      data: (productState) {
        final products = _showInactive
            ? productState.inactiveProducts
            : productState.products;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: products.isEmpty
                  ? Center(
                      child: Text(
                        _showInactive
                            ? 'No inactive products found'
                            : 'No active products found',
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () {
                        return ref
                            .read(productViewModelProvider.notifier)
                            .loadProducts();
                      },
                      child: ListView.builder(
                        padding: const EdgeInsets.only(right: 16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];

                          if (_showInactive) {
                            return InactiveProductListItem(product: product);
                          }

                          return ProductListItem(
                            product: product,
                            showAddToCart: false,
                            showManagementActions: true,
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return const ProductFormDialog();
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
