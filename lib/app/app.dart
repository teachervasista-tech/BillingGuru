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
    final auth = ref.watch(authProvider);

    // Signed in: the full app.
    if (auth.value?.user != null) {
      return MaterialApp.router(
        title: 'Billing Guru',
        theme: theme,
        routerConfig: ref.watch(appRouterProvider),
      );
    }

    final Widget home = auth.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: Center(child: Text('Unable to load user accounts:\n$error')),
      ),
      data: (state) =>
          state.needsSetup ? const SetupAdminScreen() : const LoginScreen(),
    );
    return MaterialApp(title: 'Billing Guru', theme: theme, home: home);
  }
}
