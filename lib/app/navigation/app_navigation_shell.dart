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

    final theme = Theme.of(context);

    // NavigationRail needs two or more destinations; a lone module (e.g.
    // Settings for the installer with Home off) is shown as a single item.
    final Widget destinations = items.length >= 2
        ? NavigationRail(
            selectedIndex: index >= 0 ? index : 0,
            labelType: NavigationRailLabelType.all,
            onDestinationSelected: (index) => context.go(items[index].route),
            destinations: [
              for (final item in items)
                NavigationRailDestination(
                  icon: item.icon,
                  selectedIcon: item.selectedIcon,
                  label: Text(item.label),
                ),
            ],
          )
        : Column(
            children: [
              for (final item in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    onTap: () => context.go(item.route),
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        children: [
                          IconTheme(
                            data: IconThemeData(
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                            child: item.selectedIcon,
                          ),
                          const SizedBox(height: 4),
                          Text(item.label, style: theme.textTheme.labelMedium),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );

    return Scaffold(
      body: Row(
        children: [
          // Destinations on top, the signed-in user pinned to the bottom.
          Material(
            color: theme.colorScheme.surface,
            child: SizedBox(
              width: 88,
              child: Column(
                children: [
                  // Scrolls when the window is too short for every item.
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) => SingleChildScrollView(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight,
                          ),
                          child: IntrinsicHeight(child: destinations),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1),
                  const UserMenuButton(),
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}
