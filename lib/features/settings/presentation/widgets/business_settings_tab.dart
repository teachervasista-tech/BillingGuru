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
  late final TextEditingController _name;
  late final TextEditingController _addressLine1;
  late final TextEditingController _addressLine2;
  late final TextEditingController _city;
  late final TextEditingController _state;
  late final TextEditingController _postalCode;
  late final TextEditingController _phone;
  late final TextEditingController _taxId;
  late final TextEditingController _lowStock;
  late AppSettings _draft;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _draft = ref.read(appSettingsProvider);
    final business = _draft.business;
    _name = TextEditingController(text: business.name);
    _addressLine1 = TextEditingController(text: business.addressLine1);
    _addressLine2 = TextEditingController(text: business.addressLine2);
    _city = TextEditingController(text: business.city);
    _state = TextEditingController(text: business.state);
    _postalCode = TextEditingController(text: business.postalCode);
    _phone = TextEditingController(text: business.phone);
    _taxId = TextEditingController(text: business.taxId);
    _lowStock = TextEditingController(text: '${_draft.lowStockThreshold}');
  }

  @override
  void dispose() {
    for (final controller in _businessControllers) {
      controller.dispose();
    }
    _lowStock.dispose();
    super.dispose();
  }

  List<TextEditingController> get _businessControllers => [
    _name,
    _addressLine1,
    _addressLine2,
    _city,
    _state,
    _postalCode,
    _phone,
    _taxId,
  ];

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(appSettingsProvider.notifier)
          .save(
            _draft.copyWith(
              business: BusinessDetails(
                name: _name.text.trim(),
                addressLine1: _addressLine1.text.trim(),
                addressLine2: _addressLine2.text.trim(),
                city: _city.text.trim(),
                state: _state.text.trim(),
                postalCode: _postalCode.text.trim(),
                phone: _phone.text.trim(),
                taxId: _taxId.text.trim(),
              ),
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

  Widget _field(
    String key,
    TextEditingController controller,
    String label,
    IconData icon, {
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      key: Key(key),
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      keyboardType: keyboardType,
      textInputAction: TextInputAction.next,
      validator: validator,
    );
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
                'Printed at the top of every receipt. Leave a field empty to '
                'keep it off the receipt.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _field(
                  'businessNameField',
                  _name,
                  'Business name',
                  Icons.storefront_outlined,
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'Enter the business name.'
                      : null,
                ),
                const SizedBox(height: 12),
                _field(
                  'businessAddressLine1Field',
                  _addressLine1,
                  'Address line 1',
                  Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                _field(
                  'businessAddressLine2Field',
                  _addressLine2,
                  'Address line 2',
                  Icons.home_outlined,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _field(
                        'businessCityField',
                        _city,
                        'City',
                        Icons.location_city_outlined,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: _field(
                        'businessStateField',
                        _state,
                        'State',
                        Icons.map_outlined,
                      ),
                    ),
                    SizedBox(
                      width: 200,
                      child: _field(
                        'businessPostalCodeField',
                        _postalCode,
                        'Postal code',
                        Icons.markunread_mailbox_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 12,
                  children: [
                    SizedBox(
                      width: 240,
                      child: _field(
                        'businessPhoneField',
                        _phone,
                        'Phone',
                        Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    SizedBox(
                      width: 240,
                      child: _field(
                        'businessTaxIdField',
                        _taxId,
                        'Tax ID',
                        Icons.badge_outlined,
                      ),
                    ),
                  ],
                ),
              ],
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
