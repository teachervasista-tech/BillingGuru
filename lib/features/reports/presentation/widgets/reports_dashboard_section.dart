import 'package:billing_guru/core/currency/currency_provider.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/settings/app_settings_provider.dart';
import '../../../expenses/presentation/widgets/category_spend_card.dart';
import '../providers/report_providers.dart';
import 'profit_loss_card.dart';
import 'daily_sales_card.dart';
import 'low_stock_card.dart';
import 'payment_methods_card.dart';
import 'top_products_card.dart';

class ReportsDashboardSection extends ConsumerStatefulWidget {
  const ReportsDashboardSection({
    this.showTitle = true,
    this.showFilter = true,
    this.compact = false,
    super.key,
  });

  final bool showTitle;
  final bool showFilter;
  final bool compact;

  @override
  ConsumerState<ReportsDashboardSection> createState() {
    return _ReportsDashboardSectionState();
  }
}

class _ReportsDashboardSectionState
    extends ConsumerState<ReportsDashboardSection> {
  ReportPeriodType _periodType = ReportPeriodType.last7Days;

  @override
  Widget build(BuildContext context) {
    final selectedCurrency = ref.watch(currencyProvider);
    final expensesEnabled = ref.watch(appFeaturesProvider).expensesEnabled;

    final filter = ReportFilter(type: _periodType);

    final reportAsync = ref.watch(reportProvider(filter));

    return reportAsync.when(
      loading: () {
        return const SizedBox(
          height: 280,
          child: Center(child: CircularProgressIndicator()),
        );
      },
      error: (error, stackTrace) {
        return _ReportErrorCard(
          error: error,
          onRetry: () async {
            final _ = await ref.refresh(reportProvider(filter).future);
          },
        );
      },
      data: (report) {
        return ListView(
          key: const PageStorageKey<String>('dashboard-reports'),
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            if (widget.showTitle) ...[
              Text(
                'Business overview',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Sales, products, payments, and stock overview.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (widget.showFilter) ...[
              _ReportFilterSegmentedButton(
                selectedType: _periodType,
                onTypeChanged: (type) {
                  setState(() {
                    _periodType = type;
                  });
                },
              ),
              const SizedBox(height: 24),
            ],

            ProfitLossCard(
              profitLoss: report.profitLoss,
              currency: selectedCurrency,
              periodLabel: _periodType.label,
              expenseSpend: report.expenseSpend,
            ),
            if (expensesEnabled) ...[
              const SizedBox(height: 24),
              CategorySpendCard(
                title: 'Expenses vs budget',
                spend: report.expenseSpend,
              ),
            ],
            const SizedBox(height: 24),
            DailySalesCard(
              reports: report.dailySales,
              currency: selectedCurrency,
            ),
            const SizedBox(height: 24),
            PaymentMethodsCard(
              reports: report.paymentMethods,
              currency: selectedCurrency,
            ),
            const SizedBox(height: 24),
            TopProductsCard(
              reports: report.topProducts,
              currency: selectedCurrency,
              limit: widget.compact ? 5 : 10,
            ),
            const SizedBox(height: 24),
            LowStockCard(
              products: report.lowStockProducts,
              periodLabel: _selectedPeriodLabel,
              currency: selectedCurrency,
              limit: widget.compact ? 5 : 20,
            ),
          ],
        );
      },
    );
  }

  String get _selectedPeriodLabel => _periodType.phrase;
}

class _ReportFilterSegmentedButton extends StatelessWidget {
  const _ReportFilterSegmentedButton({
    required this.selectedType,
    required this.onTypeChanged,
  });

  final ReportPeriodType selectedType;
  final ValueChanged<ReportPeriodType> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ReportPeriodType>(
      segments: [
        for (final type in ReportPeriodType.values)
          ButtonSegment(value: type, label: Text(type.label)),
      ],
      selected: {selectedType},
      onSelectionChanged: (selected) {
        if (selected.isEmpty) {
          return;
        }

        onTypeChanged(selected.first);
      },
    );
  }
}

class _ReportErrorCard extends StatelessWidget {
  const _ReportErrorCard({required this.error, required this.onRetry});

  final Object error;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              'Unable to load dashboard reports.',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                onRetry();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
