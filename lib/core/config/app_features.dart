import 'dart:convert';

import 'package:flutter/services.dart';

/// Feature (module) switches. Defaults come from
/// `assets/config/features.json`; the shop owner can override them at runtime
/// in Settings → Modules (persisted through `AppSettings`).
class AppFeatures {
  const AppFeatures([this.flags = const {}]);

  static const home = 'homeEnabled';
  static const customers = 'customersEnabled';
  static const products = 'productsEnabled';
  static const pos = 'posEnabled';
  static const sales = 'salesEnabled';
  static const reports = 'reportsEnabled';
  static const inventory = 'inventoryEnabled';
  static const expenses = 'expensesEnabled';
  static const settings = 'settingsEnabled';

  /// When false the PoS screen shows Print instead of Checkout.
  static const checkout = 'checkoutEnabled';

  static const allKeys = [
    home,
    customers,
    products,
    pos,
    sales,
    reports,
    inventory,
    expenses,
    settings,
    checkout,
  ];

  final Map<String, bool> flags;

  bool isEnabled(String key) => flags[key] ?? true;

  bool get homeEnabled => isEnabled(home);
  bool get customersEnabled => isEnabled(customers);
  bool get productsEnabled => isEnabled(products);
  bool get posEnabled => isEnabled(pos);
  bool get salesEnabled => isEnabled(sales);
  bool get reportsEnabled => isEnabled(reports);
  bool get inventoryEnabled => isEnabled(inventory);
  bool get expensesEnabled => isEnabled(expenses);
  bool get settingsEnabled => isEnabled(settings);
  bool get checkoutEnabled => isEnabled(checkout);

  AppFeatures withFlag(String key, bool value) =>
      AppFeatures({...flags, key: value});

  AppFeatures merge(Map<String, bool> overrides) =>
      AppFeatures({...flags, ...overrides});

  factory AppFeatures.fromJson(Map<String, dynamic> json) {
    return AppFeatures({
      for (final key in allKeys)
        if (json[key] is bool) key: json[key] as bool,
    });
  }

  /// Asset defaults, loaded once at startup.
  static AppFeatures instance = const AppFeatures();

  static Future<void> load() async {
    try {
      final jsonText = await rootBundle.loadString(
        'assets/config/features.json',
      );
      instance = AppFeatures.fromJson(
        jsonDecode(jsonText) as Map<String, dynamic>,
      );
    } catch (_) {
      instance = const AppFeatures();
    }
  }

  @override
  bool operator ==(Object other) =>
      other is AppFeatures &&
      allKeys.every((key) => isEnabled(key) == other.isEnabled(key));

  @override
  int get hashCode => Object.hashAll(allKeys.map(isEnabled));
}
