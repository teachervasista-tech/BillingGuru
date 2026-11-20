import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_provider.dart';

/// Receipt header lines (business name first, then address, phone and tax
/// ID), built from the separate fields in Settings → Business.
final receiptBusinessDetailsProvider = FutureProvider<String>((ref) async {
  return ref.watch(appSettingsProvider).business.receiptText;
});
