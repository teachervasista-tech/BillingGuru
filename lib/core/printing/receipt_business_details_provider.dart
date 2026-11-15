import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/app_settings_provider.dart';

/// Receipt header lines, editable in Settings → Business
/// (default: assets/config/receipt_business_details.txt).
final receiptBusinessDetailsProvider = FutureProvider<String>((ref) async {
  return ref.watch(appSettingsProvider).businessDetails.trim();
});
