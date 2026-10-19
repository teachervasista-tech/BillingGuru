import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../products/presentation/widgets/product_category_pane.dart';
import '../view_models/inventory_view_model.dart';
import '../widgets/inventory_list_item.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() {
    return _InventoryScreenState();
  }
}

class _InventorySummaryCard extends StatelessWidget {
  const _InventorySummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    Future.microtask(() {
      ref.read(inventoryViewModelProvider.notifier).loadInventory();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Refresh inventory',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(inventoryViewModelProvider.notifier).loadInventory();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          Consumer(
            builder: (context, ref, child) {
              final state = ref.watch(inventoryViewModelProvider).value;
              return CategoryNavigationPane(
                categories: state?.categories ?? const [],
                categoryCounts: state?.categoryCounts ?? const {},
                selectedCategory: state?.selectedCategory,
                onSelected: (category) => ref
                    .read(inventoryViewModelProvider.notifier)
                    .selectCategory(category),
              );
            },
          ),
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(inventoryViewModelProvider).value;
                      final totalStock = state == null
                          ? 0
                          : state.items.fold<int>(
                              0,
                              (total, item) => total + item.stockQuantity,
                            );
                      final itemCount = state?.items.length ?? 0;

                      return Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Inventory management',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _InventorySummaryCard(
                            label: 'Items',
                            value: '$itemCount',
                            icon: Icons.inventory_2_outlined,
                          ),
                          const SizedBox(width: 12),
                          _InventorySummaryCard(
                            label: 'Total stock',
                            value: '$totalStock',
                            icon: Icons.widgets_outlined,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, child) {
                      final state = ref.watch(inventoryViewModelProvider).value;
                      final lowStockOnly = state?.lowStockOnly ?? false;

                      return TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          labelText: 'Search inventory',
                          hintText: 'Search by name or barcode',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: lowStockOnly
                                    ? 'Disable low stock filter'
                                    : 'Enable low stock filter',
                                onPressed: () {
                                  ref
                                      .read(inventoryViewModelProvider.notifier)
                                      .setLowStockOnly(!lowStockOnly);
                                },
                                icon: Icon(
                                  lowStockOnly
                                      ? Icons.filter_alt
                                      : Icons.filter_alt_outlined,
                                  color: lowStockOnly
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();

                                  ref
                                      .read(inventoryViewModelProvider.notifier)
                                      .search('');
                                },
                              ),
                            ],
                          ),
                        ),
                        onChanged: (value) {
                          ref
                              .read(inventoryViewModelProvider.notifier)
                              .search(value);
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: inventoryAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, stackTrace) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Unable to load inventory:\n$error',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton(
                                onPressed: () {
                                  ref
                                      .read(inventoryViewModelProvider.notifier)
                                      .loadInventory();
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        );
                      },
                      data: (inventoryState) {
                        if (inventoryState.items.isEmpty) {
                          return const Center(
                            child: Text('No inventory items found'),
                          );
                        }

                        return RefreshIndicator(
                          onRefresh: () {
                            return ref
                                .read(inventoryViewModelProvider.notifier)
                                .loadInventory();
                          },
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            itemCount: inventoryState.items.length,
                            itemBuilder: (context, index) {
                              return InventoryListItem(
                                item: inventoryState.items[index],
                              );
                            },
                          ),
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
}
