import 'package:flutter/material.dart';

import '../../data/models/report_models.dart';

class LowStockCard extends StatelessWidget {
  const LowStockCard({
    required this.products,
    this.limit = 20,
    super.key,
    currency,
  });

  final List<LowStockReport> products;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final visibleProducts = products.take(limit).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Low-stock products',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (visibleProducts.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(
                  child: Text('No products are below the stock threshold.'),
                ),
              )
            else
              ...visibleProducts.map((product) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(product.productName),
                  subtitle: Text('Code: ${product.shortCode}'),
                  trailing: Text(
                    '${product.stockQuantity} left',
                    style: TextStyle(
                      color: product.stockQuantity <= 0
                          ? Colors.red
                          : Colors.orange.shade800,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
