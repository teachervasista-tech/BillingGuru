class SaleSummary {
  const SaleSummary({
    required this.id,
    required this.invoiceNumber,
    required this.subtotalCents,
    required this.discountCents,
    required this.taxCents,
    required this.totalCents,
    required this.paymentMethod,
    required this.createdAt,
    required this.syncStatus,
  });

  final String id;
  final String invoiceNumber;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int totalCents;
  final String paymentMethod;
  final DateTime createdAt;
  final String syncStatus;
}
