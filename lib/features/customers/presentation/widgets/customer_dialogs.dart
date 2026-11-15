import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/customer.dart';
import '../customer_providers.dart';

/// Add/edit a customer. Returns the saved customer.
Future<Customer?> showCustomerFormDialog(
  BuildContext context, {
  Customer? customer,
  String initialName = '',
}) {
  return showDialog<Customer>(
    context: context,
    builder: (_) =>
        CustomerFormDialog(customer: customer, initialName: initialName),
  );
}

class CustomerFormDialog extends ConsumerStatefulWidget {
  const CustomerFormDialog({this.customer, this.initialName = '', super.key});

  final Customer? customer;
  final String initialName;

  @override
  ConsumerState<CustomerFormDialog> createState() => _CustomerFormDialogState();
}

class _CustomerFormDialogState extends ConsumerState<CustomerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(
    text: widget.customer?.name ?? widget.initialName,
  );
  late final _phone = TextEditingController(text: widget.customer?.phone);
  late final _email = TextEditingController(text: widget.customer?.email);
  late final _address = TextEditingController(text: widget.customer?.address);
  late final _taxId = TextEditingController(text: widget.customer?.taxId);
  late final _notes = TextEditingController(text: widget.customer?.notes);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_name, _phone, _email, _address, _taxId, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final actions = ref.read(customerActionsProvider);
    final navigator = Navigator.of(context);
    try {
      final saved = await actions.save(
        Customer(
          id: widget.customer?.id ?? actions.newId(),
          name: _name.text,
          phone: _phone.text,
          email: _email.text,
          address: _address.text,
          taxId: _taxId.text,
          notes: _notes.text,
          createdAt: widget.customer?.createdAt ?? DateTime.now(),
        ),
      );
      navigator.pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Unable to save: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget field(
      TextEditingController controller,
      String label,
      IconData icon, {
      Key? key,
      int maxLines = 1,
      String? Function(String?)? validator,
      bool autofocus = false,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        key: key,
        controller: controller,
        autofocus: autofocus,
        minLines: 1,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      ),
    );

    return AlertDialog(
      title: Text(widget.customer == null ? 'Add customer' : 'Edit customer'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(
                  _name,
                  'Name',
                  Icons.person_outline,
                  key: const Key('customerNameField'),
                  autofocus: true,
                  validator: (v) =>
                      (v ?? '').trim().isEmpty ? 'Enter a name.' : null,
                ),
                field(
                  _phone,
                  'Phone',
                  Icons.phone_outlined,
                  key: const Key('customerPhoneField'),
                ),
                field(
                  _email,
                  'Email',
                  Icons.email_outlined,
                  validator: (v) {
                    final text = (v ?? '').trim();
                    if (text.isEmpty) return null;
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)
                        ? null
                        : 'Enter a valid email.';
                  },
                ),
                field(_address, 'Address', Icons.home_outlined, maxLines: 3),
                field(_taxId, 'Tax ID', Icons.badge_outlined),
                field(_notes, 'Notes', Icons.notes, maxLines: 3),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Search existing customers or quick-add one; returns the chosen customer.
class CustomerPickerDialog extends ConsumerStatefulWidget {
  const CustomerPickerDialog({super.key});

  @override
  ConsumerState<CustomerPickerDialog> createState() =>
      _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends ConsumerState<CustomerPickerDialog> {
  final _search = TextEditingController();
  List<Customer> _results = const [];

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _runSearch(String text) async {
    final results = await ref
        .read(customerServiceProvider)
        .getCustomers(search: text);
    if (mounted) setState(() => _results = results.take(50).toList());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select customer'),
      content: SizedBox(
        width: 440,
        height: 420,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Search by name, phone or email',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _runSearch,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _results.isEmpty
                  ? const Center(child: Text('No customers found.'))
                  : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final customer = _results[index];
                        return ListTile(
                          leading: const Icon(Icons.person_outline),
                          title: Text(customer.name),
                          subtitle: customer.contactLine.isEmpty
                              ? null
                              : Text(customer.contactLine),
                          onTap: () => Navigator.pop(context, customer),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton.icon(
          onPressed: () async {
            final navigator = Navigator.of(context);
            final created = await showCustomerFormDialog(
              context,
              initialName: _search.text.trim(),
            );
            if (created != null) navigator.pop(created);
          },
          icon: const Icon(Icons.person_add_alt),
          label: const Text('New customer'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
