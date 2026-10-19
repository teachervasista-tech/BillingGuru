import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../view_models/product_view_model.dart';

class ProductCategoryPane extends ConsumerWidget {
  const ProductCategoryPane({super.key, required this.productState});

  final ProductState productState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productViewModelProvider.notifier);

    return CategoryNavigationPane(
      categories: productState.categories,
      categoryCounts: productState.categoryCounts,
      selectedCategory: productState.selectedCategory,
      onSelected: notifier.selectCategory,
    );
  }
}

/// Left-hand category list shared by the Products, POS and Inventory screens.
class CategoryNavigationPane extends StatelessWidget {
  const CategoryNavigationPane({
    super.key,
    required this.categories,
    required this.categoryCounts,
    required this.selectedCategory,
    required this.onSelected,
  });

  final List<String> categories;
  final Map<String, int> categoryCounts;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final totalItems = categoryCounts.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    Widget entry(String label, String? category) {
      return ListTile(
        dense: true,
        selected: selectedCategory == category,
        selectedTileColor: Theme.of(context).colorScheme.primaryContainer
            .withValues(alpha: 0.5),
        title: Text(label, overflow: TextOverflow.ellipsis),
        onTap: () => onSelected(category),
      );
    }

    return SizedBox(
      width: 220,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            // Gives the tiles their own Material so highlights and splashes
            // are not hidden behind an opaque parent background.
            child: Material(
              type: MaterialType.transparency,
              child: ListView(
                children: [
                  entry('All ($totalItems)', null),
                  for (final category in categories)
                    entry(
                      '$category (${categoryCounts[category] ?? 0})',
                      category,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
