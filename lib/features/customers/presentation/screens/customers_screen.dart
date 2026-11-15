import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/widgets/copyright_banner.dart';
import '../../../../core/currency/currency_formatter.dart';
import '../../../../core/currency/currency_provider.dart';
import '../../../sales/presentation/screens/sales_history_screen.dart';
import '../../domain/customer.dart';
import '../customer_providers.dart';
import '../widgets/customer_dialogs.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customersProvider);
    final customers = customersAsync.value ?? const <Customer>[];
    Customer? selected;
    for (final c in customers) {
      if (c.id == _selectedId) selected = c;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Customers')),
      bottomNavigationBar: const CopyrightBanner(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await showCustomerFormDialog(context);
          if (created != null) setState(() => _selectedId = created.id);
        },
        icon: const Icon(Icons.person_add_alt),
        label: const Text('Add customer'),
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 360,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search customers',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: ref.read(customerSearchProvider.notifier).set,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: customersAsync.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('$error')),
                      data: (list) => list.isEmpty
                          ? const Center(child: Text('No customers yet.'))
                          : ListView.builder(
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final customer = list[index];
                                return ListTile(
                                  selected: customer.id == _selectedId,
                                  leading: CircleAvatar(
                                    child: Text(
                                      customer.name.characters.first
                                          .toUpperCase(),
                                    ),
                                  ),
                                  title: Text(customer.name),
                                  subtitle: customer.contactLine.isEmpty
                                      ? null
                                      : Text(customer.contactLine),
                                  onTap: () =>
                                      setState(() => _selectedId = customer.id),
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: selected == null
                ? const Center(child: Text('Select a customer to see details.'))
                : _CustomerDetails(
                    key: ValueKey(selected.id),
                    customer: selected,
                    onDeleted: () => setState(() => _selectedId = null),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerDetails extends ConsumerWidget {
  const _CustomerDetails({
    required this.customer,
    required this.onDeleted,
    super.key,
  });

  final Customer customer;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    final stats = ref.watch(customerStatsProvider(customer.id)).value;
    final salesAsync = ref.watch(customerSalesProvider(customer.id));
    String money(int cents) =>
        CurrencyFormatter.formatCents(cents, currency: currency);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(customer.name, style: theme.textTheme.headlineSmall),
            ),
            IconButton(
              tooltip: 'Edit customer',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () =>
                  showCustomerFormDialog(context, customer: customer),
            ),
            IconButton(
              tooltip: 'Delete customer',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete customer'),
                    content: Text(
                      'Delete ${customer.name}? Their past sales are kept '
                      'as walk-in sales.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  await ref.read(customerActionsProvider).delete(customer.id);
                  onDeleted();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (final (icon, value) in [
          (Icons.phone_outlined, customer.phone),
          (Icons.email_outlined, customer.email),
          (Icons.home_outlined, customer.address),
          (Icons.badge_outlined, customer.taxId),
          (Icons.notes, customer.notes),
        ])
          if (value != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: theme.colorScheme.outline),
                  const SizedBox(width: 8),
                  Expanded(child: Text(value)),
                ],
              ),
            ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Stat(
              label: 'Lifetime value',
              value: money(stats?.lifetimeValueCents ?? 0),
              valueKey: const Key('customerLifetimeValue'),
            ),
            _Stat(label: 'Purchases', value: '${stats?.purchaseCount ?? 0}'),
            _Stat(
              label: 'Average sale',
              value: money(stats?.averageSaleCents ?? 0),
            ),
            _Stat(
              label: 'Last purchase',
              value: stats?.lastPurchaseAt == null
                  ? '—'
                  : DateFormat.yMMMd().format(stats!.lastPurchaseAt!),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text('Purchase history', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        salesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (error, _) => Text('$error'),
          data: (sales) => sales.isEmpty
              ? const Text('No purchases yet.')
              : Column(
                  children: [
                    for (final sale in sales) SaleListTile(sale: sale),
                  ],
                ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.valueKey});

  final String label;
  final String value;
  final Key? valueKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(value, key: valueKey, style: theme.textTheme.titleMedium),
        ],
      ),
    );
  }
}
