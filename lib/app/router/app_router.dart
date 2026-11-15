import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_features.dart';
import '../../core/settings/app_settings_provider.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../modules.dart';
import '../navigation/app_navigation_shell.dart';

/// Kept for compatibility; prefer [moduleRouteRedirect].
String? featureRouteRedirect(String location, [AppFeatures? features]) =>
    moduleRouteRedirect(location, features ?? AppFeatures.instance);

/// Recreated for each signed-in user (so every session starts on the home
/// route); reads the *current* feature switches on every navigation so
/// toggling a module in Settings takes effect immediately.
final appRouterProvider = Provider<GoRouter>((ref) {
  ref.watch(currentUserProvider.select((user) => user?.id));
  return GoRouter(
    initialLocation: initialRoute(
      ref.read(appFeaturesProvider),
      ref.read(currentUserProvider),
    ),
    redirect: (context, state) => moduleRouteRedirect(
      state.uri.path,
      ref.read(appFeaturesProvider),
      ref.read(currentUserProvider),
    ),
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppNavigationShell(child: child),
        routes: [
          for (final module in appModules) ...[
            GoRoute(
              path: module.route,
              name: module.id,
              builder: module.builder,
            ),
            ...module.subRoutes,
          ],
        ],
      ),
    ],
  );
});
