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
        onTap: () async {
          await showDialog<bool>(
            context: context,
            builder: (context) {
              return ProductFormDialog(product: product);
            },
          );
        },
        leading: const CircleAvatar(child: Icon(Icons.inventory_2_outlined)),
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
          children: [
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

    await ref
        .read(productViewModelProvider.notifier)
        .activateProduct(product.id);
  }
}
