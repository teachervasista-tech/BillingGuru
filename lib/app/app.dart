import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/settings/app_settings_provider.dart';
import '../features/auth/presentation/auth_providers.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import 'router/app_router.dart';
import 'theme.dart';

class BillingGuru extends ConsumerWidget {
  const BillingGuru({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeId = ref.watch(
      appSettingsProvider.select((settings) => settings.colorThemeId),
    );
    final theme = buildAppTheme(AppColorTheme.byId(themeId));
    final user = ref.watch(currentUserProvider);

    if (user != null && !user.mustChangePassword) {
      return MaterialApp.router(
        title: 'Billing Guru',
        theme: theme,
        routerConfig: ref.watch(appRouterProvider),
      );
    }

    return MaterialApp(
      title: 'Billing Guru',
      theme: theme,
      home: user == null
          ? const LoginScreen()
          : const RequiredPasswordChangeScreen(),
    );
  }
}
