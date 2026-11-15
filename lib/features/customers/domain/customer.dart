import '../../../core/database/row_reader.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.createdAt,
    this.phone,
    this.email,
    this.address,
    this.taxId,
    this.notes,
  });

  final String id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxId;
  final String? notes;
  final DateTime createdAt;

  /// Second line for lists: phone and/or email.
  String get contactLine =>
      [phone, email].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  factory Customer.fromMap(Map<String, Object?> map) => Customer(
    id: map.stringOf('id'),
    name: map.stringOf('name'),
    phone: map.stringOrNull('phone'),
    email: map.stringOrNull('email'),
    address: map.stringOrNull('address'),
    taxId: map.stringOrNull('tax_id'),
    notes: map.stringOrNull('notes'),
    createdAt: map.dateOf('created_at'),
  );

  Map<String, Object?> toMap() {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();
    return {
      'id': id,
      'name': name.trim(),
      'phone': clean(phone),
      'email': clean(email),
      'address': clean(address),
      'tax_id': clean(taxId),
      'notes': clean(notes),
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// Purchase statistics (voided sales and refunds excluded).
class CustomerStats {
  const CustomerStats({
    this.purchaseCount = 0,
    this.lifetimeValueCents = 0,
    this.lastPurchaseAt,
  });

  final int purchaseCount;
  final int lifetimeValueCents;
  final DateTime? lastPurchaseAt;

  int get averageSaleCents =>
      purchaseCount == 0 ? 0 : lifetimeValueCents ~/ purchaseCount;
}
