import 'payment.dart';
import 'sale_item.dart';

class Sale {
  const Sale({
    required this.id,
    required this.invoiceNumber,
    required this.items,
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
  final List<SaleItem> items;
  final int subtotalCents;
  final int discountCents;
  final int taxCents;
  final int totalCents;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;
  final String syncStatus;
}
