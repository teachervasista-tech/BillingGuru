import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../core/currency/currency.dart';
import '../../../../core/settings/app_settings_provider.dart';
import '../../../checkout/domain/invoice_sequence.dart';

/// Business identity, regional and numbering settings that used to require
/// editing files under assets/config and rebuilding the app.
class BusinessSettingsTab extends ConsumerStatefulWidget {
  const BusinessSettingsTab({super.key});

  @override
  ConsumerState<BusinessSettingsTab> createState() =>
      _BusinessSettingsTabState();
}

class _BusinessSettingsTabState extends ConsumerState<BusinessSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _details;
  late final TextEditingController _lowStock;
  late AppSettings _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(appSettingsProvider);
    _details = TextEditingController(text: _draft.businessDetails);
    _lowStock = TextEditingController(text: '${_draft.lowStockThreshold}');
  }

  @override
  void dispose() {
    _details.dispose();
    _lowStock.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(appSettingsProvider.notifier)
          .save(
            _draft.copyWith(
              businessDetails: _details.text.trim(),
              lowStockThreshold: int.parse(_lowStock.text.trim()),
            ),
          );
      messenger.showSnackBar(
        const SnackBar(content: Text('Business settings saved')),
      );
    } catch (error) {
      messenger.showSnackBar(
        SnackBar(content: Text('Unable to save settings: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final sequence = InvoiceSequenceReset.parse(_draft.invoiceSequence);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionCard(
            title: 'Business details',
            description:
                'Printed at the top of every receipt. The first line is used '
                'as the business name.',
            child: TextFormField(
              key: const Key('businessDetailsField'),
              controller: _details,
              minLines: 4,
              maxLines: 8,
              decoration: const InputDecoration(
                labelText: 'Receipt header',
                alignLabelWithHint: true,
              ),
              validator: (value) => (value ?? '').trim().isEmpty
                  ? 'Enter at least the business name.'
                  : null,
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Regional',
            child: Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<String>(
                    initialValue: AppCurrency.fromCode(_draft.currencyCode)
                        .code,
                    decoration: const InputDecoration(
                      labelText: 'Currency',
                      prefixIcon: Icon(Icons.payments_outlined),
                    ),
                    items: [
                      for (final currency in AppCurrency.supported)
                        DropdownMenuItem(
                          value: currency.code,
                          child: Text(currency.displayName),
                        ),
                    ],
                    onChanged: (code) => setState(
                      () => _draft = _draft.copyWith(currencyCode: code),
                    ),
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int>(
                    initialValue: _draft.financialYearStartMonth,
                    decoration: const InputDecoration(
                      labelText: 'Financial year starts in',
                      prefixIcon: Icon(Icons.calendar_month_outlined),
                    ),
                    items: [
                      for (var month = 1; month <= 12; month++)
                        DropdownMenuItem(
                          value: month,
                          child: Text(
                            DateFormat.MMMM().format(DateTime(2000, month)),
                          ),
                        ),
                    ],
                    onChanged: (month) => setState(
                      () => _draft = _draft.copyWith(
                        financialYearStartMonth: month,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Invoice numbering',
            description:
                'How often the invoice counter restarts at 1. '
                'Next invoice looks like ${sequence.format(now, 1)}.',
            child: SegmentedButton<InvoiceSequenceReset>(
              segments: const [
                ButtonSegment(
                  value: InvoiceSequenceReset.daily,
                  label: Text('Daily'),
                ),
                ButtonSegment(
                  value: InvoiceSequenceReset.monthly,
                  label: Text('Monthly'),
                ),
                ButtonSegment(
                  value: InvoiceSequenceReset.yearly,
                  label: Text('Yearly'),
                ),
              ],
              selected: {sequence},
              onSelectionChanged: (selection) => setState(
                () => _draft = _draft.copyWith(
                  invoiceSequence: selection.first.code,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Inventory',
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: 240,
                child: TextFormField(
                  controller: _lowStock,
                  decoration: const InputDecoration(
                    labelText: 'Low-stock threshold',
                    prefixIcon: Icon(Icons.warning_amber_outlined),
                    helperText: 'Products at or below this are flagged.',
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (value) => int.tryParse(value ?? '') == null
                      ? 'Enter a whole number.'
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            title: 'Appearance',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final theme in AppColorTheme.options)
                  ChoiceChip(
                    avatar: CircleAvatar(backgroundColor: theme.seed),
                    label: Text(theme.label),
                    selected: _draft.colorThemeId == theme.id,
                    onSelected: (_) => setState(
                      () => _draft = _draft.copyWith(colorThemeId: theme.id),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save business settings'),
            ),
          ),
        ],
      ),
    );
  }
}
