import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/product.dart';
import '../view_models/product_view_model.dart';
import 'confirm_product_activation_dialog.dart';
import 'product_form_dialog.dart';

class InactiveProductListItem extends ConsumerWidget {
  const InactiveProductListItem({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Barcode: ${product.barcode}\n'
          'Stock: ${product.stockQuantity}',
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              tooltip: 'Edit product',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return ProductFormDialog(product: product);
                  },
                );
              },
            ),
            FilledButton.icon(
              icon: const Icon(Icons.restore),
              label: const Text('Reactivate'),
              onPressed: () {
                _reactivateProduct(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reactivateProduct(BuildContext context, WidgetRef ref) async {
    final confirmed = await showProductActivationDialog(
      context,
      productName: product.name,
    );

    if (!confirmed || !context.mounted) {
      return;
    }

    final success = await ref
        .read(productViewModelProvider.notifier)
        .activateProduct(product.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? '${product.name} was reactivated'
              : 'Unable to reactivate product',
        ),
      ),
    );
  }
}
