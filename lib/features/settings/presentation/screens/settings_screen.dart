import 'package:billing_guru/core/config/app_features.dart';
import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/tax/tax_rate_provider.dart';
import 'package:billing_guru/core/printing/receipt_paper_size.dart';
import 'package:billing_guru/core/printing/receipt_printer_service.dart';
import 'package:billing_guru/core/printing/receipt_business_details_provider.dart';
import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/checkout/domain/payment_option.dart';
import 'package:billing_guru/features/checkout/domain/sale.dart';
import 'package:billing_guru/features/checkout/domain/sale_item.dart';
import 'package:billing_guru/features/checkout/presentation/providers/payment_options_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final showPayments = AppFeatures.instance.checkoutEnabled;

    return DefaultTabController(
      length: showPayments ? 3 : 2,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    const Tab(icon: Icon(Icons.currency_rupee), text: 'Tax'),
                    const Tab(
                      icon: Icon(Icons.receipt_long_outlined),
                      text: 'Printer',
                    ),
                    if (showPayments)
                      const Tab(
                        icon: Icon(Icons.payments_outlined),
                        text: 'Payment options',
                      ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  const _TaxAndCurrencyTab(),
                  const _PrinterSettingsTab(),
                  if (showPayments) const _PaymentOptionsTab(),
                ],
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
      children: const [TaxRateSettingsCard()],
    );
  }
}

class _PaymentOptionsTab extends ConsumerWidget {
  const _PaymentOptionsTab();

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref, [
    PaymentOption? existing,
  ]) async {
    final nameController = TextEditingController(text: existing?.name ?? '');
    var method = existing?.method ?? PaymentMethod.digital;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existing == null ? 'Add payment option' : 'Edit payment option',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a name'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  initialValue: method,
                  decoration: const InputDecoration(labelText: 'Recorded as'),
                  items: [
                    for (final value in PaymentMethod.values)
                      DropdownMenuItem(
                        value: value,
                        child: Text(
                          '${value.name[0].toUpperCase()}${value.name.substring(1)}',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) setState(() => method = value);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop(true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    final name = nameController.text;
    // The dialog's exit animation still renders the field after the future
    // completes, so dispose the controller once it has finished.
    Future<void>.delayed(
      const Duration(milliseconds: 500),
      nameController.dispose,
    );
    if (saved != true) return;

    final notifier = ref.read(paymentOptionsProvider.notifier);
    if (existing == null) {
      await notifier.add(name, method);
    } else {
      await notifier.update(existing.id, name, method);
    }

    if (!context.mounted) return;
    // Stay on (or return to) the Payment options tab so the saved option is visible.
    DefaultTabController.maybeOf(context)?.animateTo(2);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment option "${name.trim()}" saved')),
    );
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PaymentOption option,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete payment option'),
        content: Text('Delete "${option.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(paymentOptionsProvider.notifier).delete(option.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = ref.watch(paymentOptionsProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Payment options',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (options.isEmpty)
                  const Text('No payment options. Add one to enable checkout.'),
                for (final option in options)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(option.name),
                    subtitle: Text('Recorded as ${option.method.name}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Edit',
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _edit(context, ref, option),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _delete(context, ref, option),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _edit(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add payment option'),
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

  Future<void> _showReceiptPreview(
    ReceiptTemplate template,
    AppCurrency currency,
    int taxRate,
    String businessDetails,
    ReceiptPaperSize paperSize,
  ) async {
    final sale = _sampleSale(taxRate);
    final receipt = ReceiptFormatter.format(
      sale,
      currency,
      template: template,
      businessDetails: businessDetails,
      paperSize: paperSize,
    );

    showDialog<void>(
      context: context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;

        return Dialog(
          clipBehavior: Clip.antiAlias,
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460, maxHeight: 640),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  color: scheme.primaryContainer,
                  padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: scheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${template.label} receipt preview',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: scheme.onPrimaryContainer,
                              ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close',
                        icon: const Icon(Icons.close),
                        color: scheme.onPrimaryContainer,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                Flexible(
                  child: Container(
                    width: double.infinity,
                    color: scheme.surfaceContainerHighest,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              receipt,
                              softWrap: false,
                              style: const TextStyle(
                                fontFamily: 'Consolas',
                                fontFamilyFallback: [
                                  'Courier New',
                                  'Menlo',
                                  'monospace',
                                ],
                                fontSize: 13,
                                height: 1.35,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
    final paperSize = ref.watch(receiptPaperSizeProvider);
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
                Align(
                  alignment: Alignment.centerLeft,
                  child: IntrinsicWidth(
                    child: DropdownButtonFormField<ReceiptTemplate>(
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
                  ),
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
                  alignment: Alignment.centerLeft,
                  child: IntrinsicWidth(
                    child: DropdownButtonFormField<ReceiptPaperSize>(
                      key: ValueKey(paperSize),
                      initialValue: paperSize,
                      decoration: const InputDecoration(
                        labelText: 'Printer size',
                        prefixIcon: Icon(Icons.print_outlined),
                      ),
                      items: ReceiptPaperSize.values.map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size.label),
                        );
                      }).toList(),
                      onChanged: (size) {
                        if (size != null) {
                          ref
                              .read(receiptPaperSizeProvider.notifier)
                              .select(size);
                        }
                      },
                    ),
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
                            paperSize,
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
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 220,
                  child: TextFormField(
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
                ),
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
