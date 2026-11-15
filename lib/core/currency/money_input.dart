/// Parsing/formatting for money text fields (accepts "2.50" or "2,50").
class MoneyInput {
  const MoneyInput._();

  /// Cents for [text], or null when empty or invalid.
  static int? parse(String? text) {
    final normalized = (text ?? '').trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final value = double.tryParse(normalized);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  static String format(int cents) => (cents / 100).toStringAsFixed(2);

  static String? requiredValidator(String? text) {
    if ((text ?? '').trim().isEmpty) return 'Amount is required.';
    return parse(text) == null ? 'Enter a valid amount.' : null;
  }

  static String? positiveValidator(String? text) {
    final error = requiredValidator(text);
    if (error != null) return error;
    return parse(text)! <= 0 ? 'Amount must be greater than zero.' : null;
  }

  static String? optionalValidator(String? text) {
    if ((text ?? '').trim().isEmpty) return null;
    return parse(text) == null ? 'Enter a valid amount.' : null;
  }
}
