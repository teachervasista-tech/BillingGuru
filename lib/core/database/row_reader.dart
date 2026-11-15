/// Typed accessors for sqflite result rows.
///
/// SQLite aggregates (`SUM`, `COUNT`) may come back as `int`, `double` or
/// `null` depending on the data, so these normalise them in one place.
extension RowReader on Map<String, Object?> {
  int intOf(String key, [int fallback = 0]) {
    final value = this[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return fallback;
    return int.tryParse('$value') ?? fallback;
  }

  int? intOrNull(String key) {
    final value = this[key];
    if (value == null) return null;
    return intOf(key);
  }

  String stringOf(String key, [String fallback = '']) {
    final value = this[key];
    return value == null ? fallback : '$value';
  }

  String? stringOrNull(String key) {
    final value = this[key];
    return value == null ? null : '$value';
  }

  bool boolOf(String key, [bool fallback = false]) {
    final value = this[key];
    if (value == null) return fallback;
    if (value is bool) return value;
    return intOf(key) != 0;
  }

  DateTime dateOf(String key) => DateTime.parse(this[key] as String);

  DateTime? dateOrNull(String key) {
    final value = this[key];
    return value == null ? null : DateTime.tryParse('$value');
  }
}
