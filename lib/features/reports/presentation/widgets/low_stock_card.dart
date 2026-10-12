import 'package:flutter/material.dart';

import '../../data/models/report_models.dart';

class LowStockCard extends StatelessWidget {
  const LowStockCard({
    required this.products,
    required this.periodLabel,
    this.limit = 20,
    super.key,
    currency,
  });

  final List<LowStockReport> products;
  final String periodLabel;
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
              'Slow-moving products',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (visibleProducts.isEmpty)
              const SizedBox(
                height: 120,
                child: Center(
                  child: Text('No low-selling products in this period.'),
                ),
              )
            else
              ...visibleProducts.map((product) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.trending_down_outlined,
                    color: Colors.orange,
                  ),
                  title: Text(product.productName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${product.shortCode}'),
                      Text(
                        product.soldQuantity == 0
                            ? 'Not sold $periodLabel'
                            : 'Sold ${product.soldQuantity} $periodLabel',
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${product.soldQuantity} sold',
                    style: TextStyle(
                      color: product.soldQuantity == 0
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
