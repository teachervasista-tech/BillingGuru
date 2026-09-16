import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../../data/models/product.dart';
import '../view_models/product_view_model.dart';
import 'confirm_product_deactivation_dialog.dart';
//import '../view_models/product_view_model.dart';
import 'product_form_dialog.dart';

class ProductListItem extends ConsumerWidget {
  const ProductListItem({
    super.key,
    required this.product,
    this.showAddToCart = true,
    this.showManagementActions = true,
  });

  final Product product;
  final bool showAddToCart;
  final bool showManagementActions;

  String formatMoney(int cents) {
    return '€${(cents / 100).toStringAsFixed(2)}';
  }

  Future<void> _editProduct(BuildContext context) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ProductFormDialog(product: product);
      },
    );

    if (!context.mounted) {
      return;
    }

    if (updated == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isOutOfStock = product.stockQuantity <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          child: Icon(Icons.inventory_2, color: colorScheme.onPrimaryContainer),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Code: ${product.shortCode}\n'
          'Category: ${product.category}\n'
          'Stock: ${product.stockQuantity}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatMoney(product.priceCents),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showManagementActions)
              IconButton(
                tooltip: 'Edit product',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  _editProduct(context);
                },
              ),
            if (showManagementActions)
              IconButton(
                tooltip: 'Deactivate product',
                icon: const Icon(Icons.delete_outline),
                color: Colors.red,
                onPressed: () {
                  _deactivateProduct(context, ref);
                },
              ),
            if (showAddToCart)
              FilledButton.icon(
                onPressed: isOutOfStock
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).addProduct(product);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart'),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('Add'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _deactivateProduct(BuildContext context, WidgetRef ref) async {
    final confirmed = await showProductDeactivationDialog(
      context,
      productName: product.name,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final success = await ref
        .read(productViewModelProvider.notifier)
        .deactivateProduct(product.id);

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} was deactivated'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () {
              ref
                  .read(productViewModelProvider.notifier)
                  .activateProduct(product.id);
            },
          ),
        ),
      );
    } else {
      final error = ref.read(productViewModelProvider).error;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Unable to deactivate product.'),
        ),
      );
    }
  }
}
