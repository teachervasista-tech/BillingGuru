import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/currency/currency_provider.dart';
import '../../domain/expense.dart';

/// Spend per category with a budget bar where a monthly budget is set.
/// Used on the Expenses screen and the Reports P&L section.
class CategorySpendCard extends ConsumerWidget {
  const CategorySpendCard({
    required this.spend,
    this.title = 'Spending by category',
    this.selectedCategoryId,
    this.onCategoryTap,
    super.key,
  });

  final List<CategorySpend> spend;
  final String title;
  final String? selectedCategoryId;
  final ValueChanged<String>? onCategoryTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencyProvider);
    final theme = Theme.of(context);
    String money(int cents) =>
        CurrencyFormatter.formatCents(cents, currency: currency);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            if (spend.isEmpty)
              Text(
                'No expenses in this period.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            for (final item in spend)
              InkWell(
                onTap: onCategoryTap == null
                    ? null
                    : () => onCategoryTap!(item.category.id),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 4,
                  ),
                  decoration: selectedCategoryId == item.category.id
                      ? BoxDecoration(
                          color: theme.colorScheme.primaryContainer.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 6,
                            backgroundColor: Color(item.category.color),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(item.category.name)),
                          Text(
                            item.budgetCents > 0
                                ? '${money(item.spentCents)} / ${money(item.budgetCents)}'
                                : money(item.spentCents),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: item.isOverBudget
                                  ? theme.colorScheme.error
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      if (item.budgetCents > 0) ...[
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: item.budgetUsage.clamp(0, 1).toDouble(),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                          color: item.isOverBudget
                              ? theme.colorScheme.error
                              : item.budgetUsage > 0.8
                              ? Colors.orange
                              : Color(item.category.color),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
