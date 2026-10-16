import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/tax/tax_rate_provider.dart';
import 'package:billing_guru/core/printing/receipt_printer_service.dart';
import 'package:billing_guru/core/printing/receipt_business_details_provider.dart';
import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/checkout/domain/sale.dart';
import 'package:billing_guru/features/checkout/domain/sale_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Theme.of(context).dividerColor),
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(icon: Icon(Icons.currency_rupee), text: 'Tax'),
                    Tab(
                      icon: Icon(Icons.receipt_long_outlined),
                      text: 'Printer',
                    ),
                  ],
                ),
              ),
            ),
            const Expanded(
              child: TabBarView(
                children: [_TaxAndCurrencyTab(), _PrinterSettingsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaxAndCurrencyTab extends StatelessWidget {
  const _TaxAndCurrencyTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: const [
        AssetCurrencyCard(),
        SizedBox(height: 16),
        TaxRateSettingsCard(),
      ],
    );
  }
}

class _PrinterSettingsTab extends ConsumerStatefulWidget {
  const _PrinterSettingsTab();

  @override
  ConsumerState<_PrinterSettingsTab> createState() {
    return _PrinterSettingsTabState();
  }
}

class _PrinterSettingsTabState extends ConsumerState<_PrinterSettingsTab> {
  bool _isSaving = false;

  Future<void> _selectTemplate(ReceiptTemplate template) async {
    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(receiptTemplateProvider.notifier).selectTemplate(template);
    } catch (error) {
      debugPrint('Unable to save the receipt template: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showReceiptPreview(
    ReceiptTemplate template,
    AppCurrency currency,
    int taxRate,
    String businessDetails,
  ) {
    final sale = _sampleSale(taxRate);
    final receipt = ReceiptFormatter.format(
      sale,
      currency,
      template: template,
      businessDetails: businessDetails,
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('${template.label} receipt preview'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Text(
                  receipt,
                  style: const TextStyle(fontFamily: 'monospace', height: 1.5),
                ),
              ),
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Sale _sampleSale(int taxRate) {
    const invoiceNumber = 'BG-1042';
    const subtotalCents = 3250;
    final taxCents = subtotalCents * taxRate ~/ 100;

    return Sale(
      id: 'receipt-preview',
      invoiceNumber: invoiceNumber,
      items: const [
        SaleItem(
          id: 'preview-1',
          saleId: 'receipt-preview',
          productId: 'Coffee beans',
          productName: 'Coffee beans',
          quantity: 2,
          unitPriceCents: 1250,
          totalCents: 2500,
        ),
        SaleItem(
          id: 'preview-2',
          saleId: 'receipt-preview',
          productId: 'Pastry',
          productName: 'Pastry',
          quantity: 1,
          unitPriceCents: 750,
          totalCents: 750,
        ),
      ],
      subtotalCents: subtotalCents,
      discountCents: 0,
      taxCents: taxCents,
      totalCents: subtotalCents + taxCents,
      paymentMethod: PaymentMethod.card,
      createdAt: DateTime.now(),
      syncStatus: 'synced',
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedTemplate = ref.watch(receiptTemplateProvider);
    final currency = ref.watch(currencyProvider);
    final taxRate = ref.watch(defaultTaxRateProvider);
    final businessDetailsAsync = ref.watch(receiptBusinessDetailsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill receipt template',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a layout for bill receipt previews and printing.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Receipt business details',
                  style: Theme.of(context).textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Loaded from assets/config/receipt_business_details.txt',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                businessDetailsAsync.when(
                  data: (details) => SelectableText(details),
                  loading: () => const LinearProgressIndicator(),
                  error: (error, stackTrace) => const Text(
                    'Receipt business details could not be loaded.',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReceiptTemplate>(
                  key: ValueKey(selectedTemplate),
                  initialValue: selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Receipt layout',
                    prefixIcon: Icon(Icons.receipt_long_outlined),
                  ),
                  items: ReceiptTemplate.values.map((template) {
                    return DropdownMenuItem(
                      value: template,
                      child: Text(template.label),
                    );
                  }).toList(),
                  onChanged: _isSaving
                      ? null
                      : (template) {
                          if (template != null) {
                            _selectTemplate(template);
                          }
                        },
                ),
                const SizedBox(height: 8),
                Text(
                  selectedTemplate.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: businessDetailsAsync.asData == null
                        ? null
                        : () => _showReceiptPreview(
                            selectedTemplate,
                            currency,
                            taxRate,
                            businessDetailsAsync.asData!.value,
                          ),
                    icon: const Icon(Icons.visibility_outlined),
                    label: const Text('Preview receipt'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class TaxRateSettingsCard extends ConsumerStatefulWidget {
  const TaxRateSettingsCard({super.key});

  @override
  ConsumerState<TaxRateSettingsCard> createState() {
    return _TaxRateSettingsCardState();
  }
}

class _TaxRateSettingsCardState extends ConsumerState<TaxRateSettingsCard> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _taxRateController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _taxRateController = TextEditingController(
      text: ref.read(defaultTaxRateProvider).toString(),
    );
  }

  @override
  void dispose() {
    _taxRateController.dispose();
    super.dispose();
  }

  Future<void> _saveTaxRate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(defaultTaxRateProvider.notifier)
          .setDefaultTaxRate(int.parse(_taxRateController.text.trim()));
    } catch (error) {
      debugPrint('Unable to save the default tax percentage: $error');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateTaxRate(String? value) {
    final rate = int.tryParse(value?.trim() ?? '');

    if (rate == null || rate < 0 || rate > 100) {
      return 'Enter a whole number from 0 to 100.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final currentRate = ref.watch(defaultTaxRateProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tax percentage',
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Default for new products. Existing products keep their own tax rates. Current default: $currentRate%.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _taxRateController,
                decoration: const InputDecoration(
                  labelText: 'Default tax rate',
                  prefixIcon: Icon(Icons.percent),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.done,
                validator: _validateTaxRate,
                onFieldSubmitted: (_) {
                  if (!_isSaving) {
                    _saveTaxRate();
                  }
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _isSaving ? null : _saveTaxRate,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save tax rate'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AssetCurrencyCard extends ConsumerWidget {
  const AssetCurrencyCard({super.key});

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
              'Configured currency',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.currency_exchange),
              title: Text(selectedCurrency.displayName),
              subtitle: Text(selectedCurrency.code),
            ),
          ],
        ),
      ),
    );
  }
}
