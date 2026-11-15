import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/widgets/category_edit_dialog.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../inventory/presentation/view_models/inventory_view_model.dart';
import '../../data/product_category_service.dart';
import '../view_models/product_view_model.dart';

/// Settings → Product categories: add, rename, recolor, reorder, archive
/// and delete the categories used by Products, PoS and Inventory.
class ProductCategoriesTab extends ConsumerWidget {
  const ProductCategoriesTab({super.key});

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(ProductCategoryService service) action, {
    String? success,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(productCategoryServiceProvider));
      ref.invalidate(productCategoriesProvider);
      ref.invalidate(productViewModelProvider);
      ref.invalidate(inventoryViewModelProvider);
      if (success != null) {
        messenger.showSnackBar(SnackBar(content: Text(success)));
      }
    } on CategoryException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    ProductCategory? category,
  ) async {
    final draft = await showDialog<CategoryDraft>(
      context: context,
      builder: (_) => CategoryEditDialog(
        title: category == null ? 'Add category' : 'Edit category',
        name: category?.name ?? '',
        color: category?.color,
      ),
    );
    if (draft == null || !context.mounted) return;
    await _run(
      context,
      ref,
      (service) => category == null
          ? service.add(draft.name, draft.color)
          : service.update(category, name: draft.name, color: draft.color),
      success: category != null && category.name != draft.name
          ? 'Renamed on ${category.productCount} product(s)'
          : null,
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    ProductCategory category,
    List<ProductCategory> all,
  ) async {
    final others = all.where((c) => c.id != category.id).toList();
    String? target = others.isEmpty ? null : others.first.name;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Delete "${category.name}"?'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (category.productCount == 0)
                  const Text('No active products use this category.')
                else
                  Text(
                    '${category.productCount} product(s) use this category. '
                    'Move them to:',
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('moveToCategory'),
                  initialValue: target,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Move products to',
                  ),
                  items: [
                    for (final c in others)
                      DropdownMenuItem(value: c.name, child: Text(c.name)),
                  ],
                  onChanged: (v) => setState(() => target = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmDeleteCategory'),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await _run(
      context,
      ref,
      (service) => service.delete(category, moveProductsTo: target),
      success: 'Category "${category.name}" deleted',
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(productCategoriesProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Product categories',
          description:
              'Used to group products on the PoS, Products and Inventory '
              'screens, in this order. Renaming a category updates its '
              'products. Archived categories are not offered for new or '
              'edited products.',
          trailing: FilledButton.icon(
            key: const Key('addProductCategory'),
            onPressed: () => _edit(context, ref, null),
            icon: const Icon(Icons.add),
            label: const Text('Add category'),
          ),
          child: categoriesAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('Unable to load categories: $error'),
            data: (categories) => Column(
              children: [
                for (final (index, category) in categories.indexed)
                  ListTile(
                    key: Key('pcat-${category.name}'),
                    leading: CircleAvatar(
                      radius: 10,
                      backgroundColor: Color(category.color),
                    ),
                    title: Text(
                      category.name,
                      style: category.isActive
                          ? null
                          : const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                    ),
                    subtitle: Text(
                      '${category.productCount} product'
                      '${category.productCount == 1 ? '' : 's'}'
                      '${category.isActive ? '' : ' · archived'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Move up',
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: index == 0
                              ? null
                              : () => _run(
                                  context,
                                  ref,
                                  (s) => s.move(category.id, -1),
                                ),
                        ),
                        IconButton(
                          tooltip: 'Move down',
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: index == categories.length - 1
                              ? null
                              : () => _run(
                                  context,
                                  ref,
                                  (s) => s.move(category.id, 1),
                                ),
                        ),
                        Tooltip(
                          message: category.isActive ? 'Active' : 'Archived',
                          child: Switch(
                            value: category.isActive,
                            onChanged: (active) => _run(
                              context,
                              ref,
                              (s) => s.setActive(category.id, active),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, ref, category),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: categories.length <= 1
                              ? null
                              : () =>
                                    _delete(context, ref, category, categories),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
