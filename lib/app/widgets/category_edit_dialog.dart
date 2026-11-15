import 'package:flutter/material.dart';

import '../../core/currency/money_input.dart';
import '../../core/database/migrations.dart';

/// Result of [CategoryEditDialog].
class CategoryDraft {
  const CategoryDraft(this.name, this.color, {this.budgetCents = 0});

  final String name;
  final int color;
  final int budgetCents;
}

/// Name + color (+ optional monthly budget) editor shared by product and
/// expense categories.
class CategoryEditDialog extends StatefulWidget {
  const CategoryEditDialog({
    required this.title,
    this.name = '',
    this.color,
    this.showBudget = false,
    this.budgetCents = 0,
    super.key,
  });

  final String title;
  final String name;
  final int? color;
  final bool showBudget;
  final int budgetCents;

  @override
  State<CategoryEditDialog> createState() => _CategoryEditDialogState();
}

class _CategoryEditDialogState extends State<CategoryEditDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.name);
  late final _budget = TextEditingController(
    text: widget.budgetCents > 0 ? MoneyInput.format(widget.budgetCents) : '',
  );
  late int _color = widget.color ?? categoryPalette.first;

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('categoryNameField'),
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter a name.' : null,
              ),
              if (widget.showBudget) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _budget,
                  decoration: const InputDecoration(
                    labelText: 'Monthly budget (optional)',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: MoneyInput.optionalValidator,
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final color in categoryPalette)
                    InkWell(
                      onTap: () => setState(() => _color = color),
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor: Color(color),
                        child: _color == color
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('categorySaveButton'),
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              CategoryDraft(
                _name.text.trim(),
                _color,
                budgetCents: MoneyInput.parse(_budget.text) ?? 0,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
