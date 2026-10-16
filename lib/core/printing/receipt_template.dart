enum ReceiptTemplate { classic, compact, detailed }

extension ReceiptTemplateDetails on ReceiptTemplate {
  String get label {
    return switch (this) {
      ReceiptTemplate.classic => 'Classic',
      ReceiptTemplate.compact => 'Compact',
      ReceiptTemplate.detailed => 'Detailed',
    };
  }

  String get description {
    return switch (this) {
      ReceiptTemplate.classic => 'Balanced layout with totals and payment.',
      ReceiptTemplate.compact => 'Space-saving layout for short receipts.',
      ReceiptTemplate.detailed => 'Includes per-item prices and discounts.',
    };
  }
}

ReceiptTemplate receiptTemplateFromName(String? name) {
  return ReceiptTemplate.values.firstWhere(
    (template) => template.name == name,
    orElse: () => ReceiptTemplate.classic,
  );
}
