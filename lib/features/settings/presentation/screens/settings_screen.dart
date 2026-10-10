import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/currency/currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencySettingsCard extends ConsumerWidget {
  const CurrencySettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(currencyProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose the currency used throughout BillingApp.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: AppCurrency.supported.map((currency) {
                return ChoiceChip(
                  label: Text(currency.displayName),
                  selected: selectedCurrency.code == currency.code,
                  onSelected: (_) {
                    ref
                        .read(currencyProvider.notifier)
                        .selectCurrency(currency);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
