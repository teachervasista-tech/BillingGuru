import 'dart:convert';

import 'package:flutter/services.dart';

class AppFeatures {
  AppFeatures._({
    required this.homeEnabled,
    required this.customersEnabled,
    required this.productsEnabled,
    required this.posEnabled,
    required this.salesEnabled,
    required this.reportsEnabled,
    required this.inventoryEnabled,
    required this.settingsEnabled,
  });

  final bool homeEnabled;
  final bool customersEnabled;
  final bool productsEnabled;
  final bool posEnabled;
  final bool salesEnabled;
  final bool reportsEnabled;
  final bool inventoryEnabled;
  final bool settingsEnabled;

  static late AppFeatures instance;

  static Future<void> load() async {
    final jsonText = await rootBundle.loadString('assets/config/features.json');

    final values = jsonDecode(jsonText) as Map<String, dynamic>;

    instance = AppFeatures._(
      homeEnabled: values['homeEnabled'] as bool? ?? true,
      customersEnabled: values['customersEnabled'] as bool? ?? true,
      productsEnabled: values['productsEnabled'] as bool? ?? true,
      posEnabled: values['posEnabled'] as bool? ?? true,
      salesEnabled: values['salesEnabled'] as bool? ?? true,
      reportsEnabled: values['reportsEnabled'] as bool? ?? true,
      inventoryEnabled: values['inventoryEnabled'] as bool? ?? true,
      settingsEnabled: values['settingsEnabled'] as bool? ?? true,
    );
  }
}
