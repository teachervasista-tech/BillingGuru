import 'package:billing_guru/core/currency/currency_formatter.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/features/products/presentation/widgets/product_thumbnail.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../cart/presentation/view_models/cart_view_model.dart';
import '../../data/models/product.dart';
import '../view_models/product_view_model.dart';
import 'confirm_product_deactivation_dialog.dart';
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

  String formatMoney(WidgetRef ref, int cents) {
    final currency = ref.watch(currencyProvider);

    return CurrencyFormatter.formatCents(cents, currency: currency);
  }

  Future<void> _editProduct(BuildContext context) async {
    await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return ProductFormDialog(product: product);
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    // In the POS list, show what is still available after the cart's items.
    final inCart = showAddToCart
        ? ref.watch(
            cartProvider.select((items) {
              for (final item in items) {
                if (item.product.id == product.id) return item.quantity;
              }
              return 0;
            }),
          )
        : 0;
    final availableStock = product.stockQuantity - inCart;
    final isOutOfStock = availableStock <= 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        minTileHeight: 88,
        titleAlignment: ListTileTitleAlignment.center,
        onTap: showManagementActions ? () => _editProduct(context) : null,
        leading: ProductThumbnail(
          imagePath: product.imagePath,
          width: 56,
          height: 88,
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Code: ${product.shortCode}\n'
          'Category: ${product.category}\n'
          'Stock: $availableStock',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              formatMoney(ref, product.priceCents),
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
              FilledButton(
                onPressed: isOutOfStock
                    ? null
                    : () {
                        ref.read(cartProvider.notifier).addProduct(product);
                      },
                child: const Text('Add'),
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

    await ref
        .read(productViewModelProvider.notifier)
        .deactivateProduct(product.id);
  }
}
