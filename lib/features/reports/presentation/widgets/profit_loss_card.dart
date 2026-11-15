import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/currency/currency.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/export/csv_export.dart';
import '../../../expenses/domain/expense.dart';
import '../../data/models/report_models.dart';

class ProfitLossCard extends StatelessWidget {
  const ProfitLossCard({
    required this.profitLoss,
    required this.currency,
    required this.periodLabel,
    this.expenseSpend = const [],
    super.key,
  });

  final ProfitLoss profitLoss;
  final AppCurrency currency;
  final String periodLabel;
  final List<CategorySpend> expenseSpend;

  String _money(int cents) =>
      CurrencyFormatter.formatCents(cents, currency: currency);

  Future<void> _export(BuildContext context) async {
    final pl = profitLoss;
    final messenger = ScaffoldMessenger.of(context);
    final path = await CsvExport.save(
      suggestedName:
          'profit-and-loss-${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
      rows: [
        ['Profit & loss', periodLabel],
        [],
        ['Sales (incl. tax)', CsvExport.amount(pl.salesCents)],
        ['Tax collected', CsvExport.amount(pl.taxCollectedCents)],
        ['Net sales', CsvExport.amount(pl.netSalesCents)],
        ['Cost of goods sold', CsvExport.amount(pl.cogsCents)],
        ['Gross profit', CsvExport.amount(pl.grossProfitCents)],
        ['Operating expenses', CsvExport.amount(pl.operatingExpensesCents)],
        ['Net profit', CsvExport.amount(pl.netProfitCents)],
        [],
        [
          'Stock purchases (inventory)',
          CsvExport.amount(pl.stockPurchasesCents),
        ],
        ['Cash flow', CsvExport.amount(pl.cashFlowCents)],
        [],
        ['Expenses by category', 'Spent', 'Budget'],
        for (final s in expenseSpend)
          [
            s.category.name,
            CsvExport.amount(s.spentCents),
            s.budgetCents > 0 ? CsvExport.amount(s.budgetCents) : '',
          ],
      ],
    );
    if (path != null) {
      messenger.showSnackBar(SnackBar(content: Text('Exported to $path')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pl = profitLoss;
    final percent = NumberFormat.percentPattern();

    Widget line(
      String label,
      int cents, {
      bool bold = false,
      bool negative = false,
      String? note,
      Key? key,
    }) {
      final style = bold
          ? theme.textTheme.titleSmall
          : theme.textTheme.bodyMedium;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: style)),
            if (note != null)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Text(note, style: theme.textTheme.bodySmall),
              ),
            Text(
              negative ? '− ${_money(cents)}' : _money(cents),
              key: key,
              style: style?.copyWith(
                color: bold && cents < 0 ? theme.colorScheme.error : null,
              ),
            ),
          ],
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Profit & loss · $periodLabel',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Export profit & loss to CSV',
                  icon: const Icon(Icons.download_outlined),
                  onPressed: () => _export(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _Kpi(
                  label: 'Net sales',
                  value: _money(pl.netSalesCents),
                  icon: Icons.trending_up,
                ),
                _Kpi(
                  label: 'Gross profit',
                  value: _money(pl.grossProfitCents),
                  detail: '${percent.format(pl.grossMargin)} margin',
                  icon: Icons.inventory_2_outlined,
                ),
                _Kpi(
                  label: 'Expenses',
                  value: _money(pl.operatingExpensesCents),
                  icon: Icons.account_balance_wallet_outlined,
                ),
                _Kpi(
                  label: 'Net profit',
                  value: _money(pl.netProfitCents),
                  detail: '${percent.format(pl.netMargin)} margin',
                  icon: pl.netProfitCents >= 0
                      ? Icons.savings_outlined
                      : Icons.warning_amber,
                  negative: pl.netProfitCents < 0,
                ),
              ],
            ),
            const Divider(height: 32),
            line('Sales (incl. tax)', pl.salesCents),
            line('Tax collected', pl.taxCollectedCents, negative: true),
            line('Net sales', pl.netSalesCents, bold: true),
            line('Cost of goods sold', pl.cogsCents, negative: true),
            line('Gross profit', pl.grossProfitCents, bold: true),
            line(
              'Operating expenses',
              pl.operatingExpensesCents,
              negative: true,
            ),
            line(
              'Net profit',
              pl.netProfitCents,
              bold: true,
              key: const Key('netProfitValue'),
            ),
            const Divider(height: 24),
            line(
              'Stock purchases',
              pl.stockPurchasesCents,
              note: 'inventory, counted in COGS when sold',
            ),
            line('Cash flow (in − out)', pl.cashFlowCents, bold: true),
            if (pl.unitsWithoutCost > 0) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pl.unitsWithoutCost} unit(s) sold had no cost price, '
                      'so COGS is understated. Set cost prices in Products.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Kpi extends StatelessWidget {
  const _Kpi({
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.negative = false,
  });

  final String label;
  final String value;
  final String? detail;
  final IconData icon;
  final bool negative;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = negative
        ? theme.colorScheme.error
        : theme.colorScheme.primary;
    return Container(
      width: 200,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodySmall),
                Text(
                  value,
                  style: theme.textTheme.titleMedium?.copyWith(color: color),
                ),
                if (detail != null)
                  Text(detail!, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
