import 'dart:convert';

import 'payment.dart';

class PaymentOption {
  const PaymentOption({
    required this.id,
    required this.name,
    required this.method,
  });

  final String id;
  final String name;

  /// Underlying method persisted with the sale.
  final PaymentMethod method;

  PaymentOption copyWith({String? name, PaymentMethod? method}) {
    return PaymentOption(
      id: id,
      name: name ?? this.name,
      method: method ?? this.method,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'method': method.name,
  };

  factory PaymentOption.fromJson(Map<String, Object?> json) {
    return PaymentOption(
      id: json['id'] as String,
      name: json['name'] as String,
      method: PaymentMethod.values.firstWhere(
        (value) => value.name == json['method'],
        orElse: () => PaymentMethod.digital,
      ),
    );
  }

  static String encodeList(List<PaymentOption> options) {
    return jsonEncode(options.map((option) => option.toJson()).toList());
  }

  static List<PaymentOption> decodeList(String source) {
    final decoded = jsonDecode(source) as List<dynamic>;
    return decoded
        .map(
          (item) =>
              PaymentOption.fromJson(Map<String, Object?>.from(item as Map)),
        )
        .toList();
  }
}

const defaultPaymentOptions = [
  PaymentOption(id: 'cash', name: 'Pay by Cash', method: PaymentMethod.cash),
  PaymentOption(id: 'card', name: 'Pay by Card', method: PaymentMethod.card),
];
