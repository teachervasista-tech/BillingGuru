import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../settings/app_settings_provider.dart';
import 'currency.dart';

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) {
  return SharedPreferences.getInstance();
});

/// Currency chosen in Settings (default: assets/config/currency.txt).
final currencyProvider = Provider<AppCurrency>((ref) {
  return AppCurrency.fromCode(ref.watch(appSettingsProvider).currencyCode);
});
