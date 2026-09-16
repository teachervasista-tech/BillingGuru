import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../view_models/inventory_view_model.dart';
import '../widgets/inventory_list_item.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() {
    return _InventoryScreenState();
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
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Inventory management',
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Search inventory',
                            hintText: 'Search by name or barcode',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();

                                ref
                                    .read(inventoryViewModelProvider.notifier)
                                    .search('');
                              },
                            ),
                          ),
                          onChanged: (value) {
                            ref
                                .read(inventoryViewModelProvider.notifier)
                                .search(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Consumer(
                        builder: (context, ref, child) {
                          final state = ref
                              .watch(inventoryViewModelProvider)
                              .value;

                          return FilterChip(
                            label: const Text('Low stock only'),
                            selected: state?.lowStockOnly ?? false,
                            onSelected: (value) {
                              ref
                                  .read(inventoryViewModelProvider.notifier)
                                  .setLowStockOnly(value);
                            },
                          );
                        },
                      ),
                    ],
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
