import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/dashboard_summary.dart';
import '../view_models/dashboard_view_model.dart';
import '../../../../app/widgets/copyright_banner.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh dashboard',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(dashboardViewModelProvider.notifier).loadDashboard();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          const VerticalDivider(width: 1, thickness: 1),
          Expanded(
            child: dashboardAsync.when(
              loading: () {
                return const Center(child: CircularProgressIndicator());
              },
              error: (error, stackTrace) {
                return _DashboardError(
                  error: error,
                  onRetry: () {
                    ref
                        .read(dashboardViewModelProvider.notifier)
                        .loadDashboard();
                  },
                );
              },
              data: (summary) {
                return _DashboardContent(
                  summary: summary,
                  onRefresh: () {
                    return ref
                        .read(dashboardViewModelProvider.notifier)
                        .loadDashboard();
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CopyrightBanner(),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.summary, required this.onRefresh});

  final DashboardSummary summary;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 900;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Business summary for today',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: isWide ? 1.55 : 1.35,
                children: [
                  _MetricCard(
                    title: 'Today’s sales',
                    value: _formatMoney(summary.todaySalesCents),
                    icon: Icons.euro,
                    color: Colors.green,
                  ),
                  _MetricCard(
                    title: 'Sales count',
                    value: '${summary.todaySalesCount}',
                    icon: Icons.receipt_long,
                    color: Colors.blue,
                  ),
                  _MetricCard(
                    title: 'Active products',
                    value: '${summary.activeProductsCount}',
                    icon: Icons.inventory_2,
                    color: Colors.orange,
                  ),
                  _MetricCard(
                    title: 'Low stock',
                    value: '${summary.lowStockProductsCount}',
                    icon: Icons.warning_amber,
                    color: Colors.red,
                  ),
                ],
              ),
              const SizedBox(height: 32),
              _QuickActions(),
              const SizedBox(height: 32),
              Text(
                'Recent sales',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              if (summary.recentSales.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('No sales recorded yet')),
                  ),
                )
              else
                ...summary.recentSales.map(
                  (sale) => _RecentSaleTile(sale: sale),
                ),
            ],
          );
        },
      ),
    );
  }

  String _formatMoney(int cents) {
    return '€${(cents / 100).toStringAsFixed(2)}';
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.15),
              foregroundColor: color,
              child: Icon(icon),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: () {
            context.go('/pos');
          },
          icon: const Icon(Icons.point_of_sale),
          label: const Text('Open PoS'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            context.go('/products');
          },
          icon: const Icon(Icons.inventory_2),
          label: const Text('Manage products'),
        ),
        OutlinedButton.icon(
          onPressed: () {
            context.go('/sales');
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('View sales'),
        ),
      ],
    );
  }
}

class _RecentSaleTile extends StatelessWidget {
  const _RecentSaleTile({required this.sale});

  final RecentSale sale;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.receipt_long)),
        title: Text(
          sale.invoiceNumber,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${_formatDate(sale.createdAt)} • '
          '${sale.paymentMethod}',
        ),
        trailing: Text(
          _formatMoney(sale.totalCents),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  static String _formatDate(DateTime value) {
    final local = value.toLocal();

    String twoDigits(int number) {
      return number.toString().padLeft(2, '0');
    }

    return '${local.day}.${twoDigits(local.month)}.'
        '${local.year} '
        '${twoDigits(local.hour)}:${twoDigits(local.minute)}';
  }

  static String _formatMoney(int cents) {
    return '€${(cents / 100).toStringAsFixed(2)}';
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Unable to load dashboard:\n$error',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
