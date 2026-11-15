import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/settings/app_settings_provider.dart';
import '../../features/auth/presentation/auth_providers.dart';
import '../../features/auth/presentation/widgets/user_dialogs.dart';
import '../modules.dart';

class AppNavigationShell extends ConsumerWidget {
  const AppNavigationShell({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(appFeaturesProvider);
    final user = ref.watch(currentUserProvider);
    final items = [
      for (final module in appModules)
        if (module.showInNavigation && module.isAvailable(features, user))
          module,
    ];

    final currentPath = GoRouterState.of(context).uri.path;
    final index = items.indexWhere((item) => item.matches(currentPath));

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index >= 0 ? index : 0,
            labelType: NavigationRailLabelType.all,
            trailing: const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: UserMenuButton(),
              ),
            ),
            onDestinationSelected: (index) => context.go(items[index].route),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: item.icon,
                  selectedIcon: item.selectedIcon,
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
