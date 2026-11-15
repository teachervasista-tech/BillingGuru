import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/app_settings_provider.dart';
import 'router/app_router.dart';
import 'theme.dart';

class BillingGuru extends ConsumerWidget {
  const BillingGuru({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(
      appSettingsProvider.select((settings) => settings.colorThemeId),
    );

    return MaterialApp.router(
      title: 'Billing Guru',
      theme: buildAppTheme(AppColorTheme.byId(themeId)),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
