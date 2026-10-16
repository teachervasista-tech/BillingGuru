import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/core/printing/receipt_template_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads a saved receipt template', () async {
    SharedPreferences.setMockInitialValues({'receipt_template': 'detailed'});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(receiptTemplateProvider.notifier).loadSavedTemplate();

    expect(container.read(receiptTemplateProvider), ReceiptTemplate.detailed);
  });

  test('saves a selected receipt template', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(receiptTemplateProvider.notifier)
        .selectTemplate(ReceiptTemplate.compact);

    expect(container.read(receiptTemplateProvider), ReceiptTemplate.compact);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('receipt_template'), 'compact');
  });
}
