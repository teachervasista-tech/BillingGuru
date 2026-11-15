import '../../../checkout/domain/payment.dart';
import '../../../checkout/domain/sale.dart';
import '../../../checkout/domain/sale_item.dart';

/// Lifecycle of a sale after checkout.
enum SaleStatus {
  completed('Completed'),
  partiallyRefunded('Partly returned'),
  refunded('Returned'),
  voided('Voided');

  const SaleStatus(this.label);

  final String label;

  String get dbValue => switch (this) {
    SaleStatus.completed => 'completed',
    SaleStatus.partiallyRefunded => 'partially_refunded',
    SaleStatus.refunded => 'refunded',
    SaleStatus.voided => 'voided',
  };

  static SaleStatus parse(String? value) => SaleStatus.values.firstWhere(
    (s) => s.dbValue == value,
    orElse: () => SaleStatus.completed,
  );

  /// Items can still be returned / the sale voided.
  bool get isOpen =>
      this == SaleStatus.completed || this == SaleStatus.partiallyRefunded;
}

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
    this.status = SaleStatus.completed,
    this.refundedCents = 0,
    this.customerId,
    this.customerName,
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
  final SaleStatus status;
  final int refundedCents;
  final String? customerId;
  final String? customerName;

  /// Amount actually kept after refunds.
  int get netTotalCents => totalCents - refundedCents;

  Sale toSale(List<SaleItem> items) => Sale(
    id: id,
    invoiceNumber: invoiceNumber,
    items: items,
    subtotalCents: subtotalCents,
    discountCents: discountCents,
    taxCents: taxCents,
    totalCents: totalCents,
    paymentMethod: PaymentMethod.values.firstWhere(
      (m) => m.name == paymentMethod,
      orElse: () => PaymentMethod.cash,
    ),
    createdAt: createdAt,
    syncStatus: syncStatus,
    customerId: customerId,
    customerName: customerName,
  );
}
