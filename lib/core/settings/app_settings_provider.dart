import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_features.dart';
import '../database/database_provider.dart';
import 'app_settings.dart';
import 'settings_store.dart';

export 'app_settings.dart';

final settingsStoreProvider = Provider<SettingsStore>((ref) {
  return DatabaseSettingsStore(ref.watch(appDatabaseProvider));
});

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() =>
      AppSettings.fallback.copyWith(features: AppFeatures.instance);

  /// Loads asset defaults, then applies values saved by the user.
  Future<void> load({String? defaultColorThemeId}) async {
    final defaults = await AppSettings.loadAssetDefaults(
      colorThemeId: defaultColorThemeId,
    );
    Map<String, String> stored = const {};
    try {
      stored = await ref.read(settingsStoreProvider).readAll();
    } catch (_) {
      // Store unavailable (e.g. first run on a broken DB): use defaults.
    }
    state = defaults.applyStored(stored);
  }

  Future<void> save(AppSettings next) async {
    await ref.read(settingsStoreProvider).writeAll(next.toStore());
    state = next;
  }

  Future<void> update(AppSettings Function(AppSettings current) change) {
    return save(change(state));
  }

  Future<void> setFeature(String key, bool enabled) {
    return update(
      (s) => s.copyWith(features: s.features.withFlag(key, enabled)),
    );
  }
}

/// Effective (default + user override) feature switches.
final appFeaturesProvider = Provider<AppFeatures>((ref) {
  return ref.watch(appSettingsProvider).features;
});

/// Month number (1-12) in which the financial year starts.
final financialYearStartMonthProvider = FutureProvider<int>((ref) async {
  return ref.watch(appSettingsProvider).financialYearStartMonth;
});

final lowStockThresholdProvider = Provider<int>((ref) {
  return ref.watch(appSettingsProvider).lowStockThreshold;
});
