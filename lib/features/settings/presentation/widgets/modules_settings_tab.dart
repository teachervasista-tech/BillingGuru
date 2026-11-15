import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/modules.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../core/config/app_features.dart';
import '../../../../core/settings/app_settings_provider.dart';

/// Turn whole areas of the app on or off without rebuilding.
class ModulesSettingsTab extends ConsumerWidget {
  const ModulesSettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final features = ref.watch(appFeaturesProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    // Settings itself stays on so the user can never lock themselves out.
    final toggleable = appModules.where(
      (m) => m.featureKey != null && m.featureKey != AppFeatures.settings,
    );

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Modules',
          description: 'Hidden modules disappear from the navigation menu.',
          child: Column(
            children: [
              for (final module in toggleable)
                SwitchListTile(
                  key: Key('module-${module.id}'),
                  secondary: module.icon,
                  title: Text(module.label),
                  value: features.isEnabled(module.featureKey!),
                  onChanged: (value) =>
                      notifier.setFeature(module.featureKey!, value),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Checkout',
          child: SwitchListTile(
            key: const Key('feature-checkout'),
            secondary: const Icon(Icons.payments_outlined),
            title: const Text('Payment screen'),
            subtitle: const Text(
              'When off, the PoS records the sale as cash and prints directly.',
            ),
            value: features.checkoutEnabled,
            onChanged: (value) =>
                notifier.setFeature(AppFeatures.checkout, value),
          ),
        ),
      ],
    );
  }
}
