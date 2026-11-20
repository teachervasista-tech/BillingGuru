/// Business identity printed at the top of every receipt, edited in
/// Settings → Business.
class BusinessDetails {
  const BusinessDetails({
    this.name = '',
    this.addressLine1 = '',
    this.addressLine2 = '',
    this.city = '',
    this.state = '',
    this.postalCode = '',
    this.phone = '',
    this.taxId = '',
  });

  final String name;
  final String addressLine1;
  final String addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final String phone;
  final String taxId;

  static const defaultName = 'Billing Guru';

  static const keyName = 'business.name';
  static const keyAddressLine1 = 'business.address_line_1';
  static const keyAddressLine2 = 'business.address_line_2';
  static const keyCity = 'business.city';
  static const keyState = 'business.state';
  static const keyPostalCode = 'business.postal_code';
  static const keyPhone = 'business.phone';
  static const keyTaxId = 'business.tax_id';

  static const allKeys = [
    keyName,
    keyAddressLine1,
    keyAddressLine2,
    keyCity,
    keyState,
    keyPostalCode,
    keyPhone,
    keyTaxId,
  ];

  /// [name], or the app name when none is set.
  String get displayName {
    final trimmed = name.trim();
    return trimmed.isEmpty ? defaultName : trimmed;
  }

  /// Receipt header lines. The first line is always the business name; empty
  /// fields are left out.
  List<String> get receiptLines {
    final region = [
      state.trim(),
      postalCode.trim(),
    ].where((part) => part.isNotEmpty).join(' ');
    final cityLine = [
      city.trim(),
      region,
    ].where((part) => part.isNotEmpty).join(', ');
    return [
      displayName,
      addressLine1.trim(),
      addressLine2.trim(),
      cityLine,
      if (phone.trim().isNotEmpty) 'Phone: ${phone.trim()}',
      if (taxId.trim().isNotEmpty) 'Tax ID: ${taxId.trim()}',
    ].where((line) => line.isNotEmpty).toList();
  }

  String get receiptText => receiptLines.join('\n');

  BusinessDetails copyWith({
    String? name,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? phone,
    String? taxId,
  }) {
    return BusinessDetails(
      name: name ?? this.name,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      phone: phone ?? this.phone,
      taxId: taxId ?? this.taxId,
    );
  }

  Map<String, String> toStore() => {
    keyName: name,
    keyAddressLine1: addressLine1,
    keyAddressLine2: addressLine2,
    keyCity: city,
    keyState: state,
    keyPostalCode: postalCode,
    keyPhone: phone,
    keyTaxId: taxId,
  };

  /// True when [stored] holds any of the separate business fields.
  static bool isStoredIn(Map<String, String> stored) =>
      allKeys.any(stored.containsKey);

  static BusinessDetails fromStore(Map<String, String> stored) {
    return BusinessDetails(
      name: stored[keyName] ?? '',
      addressLine1: stored[keyAddressLine1] ?? '',
      addressLine2: stored[keyAddressLine2] ?? '',
      city: stored[keyCity] ?? '',
      state: stored[keyState] ?? '',
      postalCode: stored[keyPostalCode] ?? '',
      phone: stored[keyPhone] ?? '',
      taxId: stored[keyTaxId] ?? '',
    );
  }

  /// Converts the old free-text receipt header (business name on the first
  /// line, then address, `Phone:` and `Tax ID:` lines). Placeholder text such
  /// as `[Street Address]` is dropped. Address lines beyond the second are
  /// appended to address line 2, since city/state/postal code cannot be
  /// split out reliably.
  static BusinessDetails fromLegacyText(String text) {
    bool isPlaceholder(String value) =>
        RegExp(r'^\[.*\]$').hasMatch(value.trim());

    final lines = text
        .split(RegExp(r'\r?\n'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    if (lines.isEmpty) return const BusinessDetails();

    var phone = '';
    var taxId = '';
    final address = <String>[];
    final phonePattern = RegExp(r'^(phone|tel)\s*:\s*', caseSensitive: false);
    final taxPattern = RegExp(r'^tax\s*id\s*:\s*', caseSensitive: false);
    for (final line in lines.skip(1)) {
      if (phonePattern.hasMatch(line)) {
        final value = line.replaceFirst(phonePattern, '');
        if (!isPlaceholder(value)) phone = value;
      } else if (taxPattern.hasMatch(line)) {
        final value = line.replaceFirst(taxPattern, '');
        if (!isPlaceholder(value)) taxId = value;
      } else if (!isPlaceholder(line)) {
        address.add(line);
      }
    }

    return BusinessDetails(
      name: isPlaceholder(lines.first) ? '' : lines.first,
      addressLine1: address.isNotEmpty ? address.first : '',
      addressLine2: address.skip(1).join(', '),
      phone: phone,
      taxId: taxId,
    );
  }
}
