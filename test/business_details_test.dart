import 'package:billing_guru/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BusinessDetails', () {
    test('receipt lines skip empty fields and keep the name first', () {
      const details = BusinessDetails(
        name: 'Corner Store',
        addressLine1: 'Main Street 1',
        city: 'Springfield',
        postalCode: '62701',
        taxId: 'TX-42',
      );
      expect(details.receiptLines, [
        'Corner Store',
        'Main Street 1',
        'Springfield, 62701',
        'Tax ID: TX-42',
      ]);
      expect(const BusinessDetails().receiptLines, ['Billing Guru']);
    });

    test('migrates the old free-text header, dropping placeholders', () {
      final bundled = BusinessDetails.fromLegacyText(
        'Billing Guru\n[Street Address]\n[City, State, Postal Code]\n'
        'Phone: [Phone Number]\nTax ID: [Tax Registration Number]',
      );
      expect(bundled.receiptLines, ['Billing Guru']);

      final custom = BusinessDetails.fromLegacyText(
        'Corner Store\nMain Street 1\nSpringfield IL\nPhone: 555-0100\n'
        'Tax ID: TX-42',
      );
      expect(custom.name, 'Corner Store');
      expect(custom.addressLine1, 'Main Street 1');
      expect(custom.addressLine2, 'Springfield IL');
      expect(custom.phone, '555-0100');
      expect(custom.taxId, 'TX-42');
    });

    test('saved separate fields win over the old header', () {
      final legacyOnly = AppSettings.fallback.applyStored({
        AppSettings.keyBusinessDetails: 'Old Shop\nHigh Street',
      });
      expect(legacyOnly.businessName, 'Old Shop');
      expect(legacyOnly.business.addressLine1, 'High Street');

      final both = AppSettings.fallback.applyStored({
        AppSettings.keyBusinessDetails: 'Old Shop\nHigh Street',
        BusinessDetails.keyName: 'New Shop',
      });
      expect(both.businessName, 'New Shop');
      expect(both.business.addressLine1, '');
      expect(
        AppSettings.fallback.applyStored(both.toStore()).businessName,
        'New Shop',
      );
    });
  });
}
