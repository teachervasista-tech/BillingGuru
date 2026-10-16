import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../currency/currency_provider.dart';
import 'receipt_template.dart';

final receiptTemplateProvider =
    NotifierProvider<ReceiptTemplateNotifier, ReceiptTemplate>(
      ReceiptTemplateNotifier.new,
    );

class ReceiptTemplateNotifier extends Notifier<ReceiptTemplate> {
  static const _preferenceKey = 'receipt_template';

  @override
  ReceiptTemplate build() {
    return ReceiptTemplate.classic;
  }

  Future<void> loadSavedTemplate() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = receiptTemplateFromName(prefs.getString(_preferenceKey));
  }

  Future<void> selectTemplate(ReceiptTemplate template) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    await prefs.setString(_preferenceKey, template.name);
    state = template;
  }
}
