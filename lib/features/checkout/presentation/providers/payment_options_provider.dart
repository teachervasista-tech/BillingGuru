import 'package:billing_guru/core/currency/currency_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../domain/payment.dart';
import '../../domain/payment_option.dart';

final paymentOptionsProvider =
    NotifierProvider<PaymentOptionsNotifier, List<PaymentOption>>(
      PaymentOptionsNotifier.new,
    );

class PaymentOptionsNotifier extends Notifier<List<PaymentOption>> {
  static const _preferenceKey = 'payment_options';
  static const _uuid = Uuid();

  @override
  List<PaymentOption> build() {
    _load();
    return defaultPaymentOptions;
  }

  Future<void> _load() async {
    try {
      final prefs = await ref.read(sharedPreferencesProvider.future);
      final saved = prefs.getString(_preferenceKey);
      if (saved != null) {
        state = PaymentOption.decodeList(saved);
      }
    } catch (_) {
      state = defaultPaymentOptions;
    }
  }

  Future<void> _save(List<PaymentOption> options) async {
    state = options;
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_preferenceKey, PaymentOption.encodeList(options));
  }

  Future<void> add(String name, PaymentMethod method) {
    return _save([
      ...state,
      PaymentOption(id: _uuid.v4(), name: name.trim(), method: method),
    ]);
  }

  Future<void> update(String id, String name, PaymentMethod method) {
    return _save([
      for (final option in state)
        option.id == id
            ? option.copyWith(name: name.trim(), method: method)
            : option,
    ]);
  }

  Future<void> delete(String id) {
    return _save(state.where((option) => option.id != id).toList());
  }
}
