import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/period/date_range.dart';
import '../../core/settings/app_settings_provider.dart';

/// Period picker shared by Sales history, Expenses and Reports. Labels use
/// the financial year configured in Settings.
class PeriodDropdown extends ConsumerWidget {
  const PeriodDropdown({
    required this.selected,
    required this.onChanged,
    this.options = PeriodPreset.values,
    this.width = 280,
    super.key,
  });

  final PeriodPreset selected;
  final ValueChanged<PeriodPreset> onChanged;
  final List<PeriodPreset> options;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final startMonth = ref.watch(
      appSettingsProvider.select((s) => s.financialYearStartMonth),
    );
    final now = DateTime.now();

    return SizedBox(
      width: width,
      child: DropdownButtonFormField<PeriodPreset>(
        key: ValueKey(selected),
        initialValue: selected,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Period',
          prefixIcon: Icon(Icons.date_range_outlined),
        ),
        items: [
          for (final period in options)
            DropdownMenuItem(
              value: period,
              child: Text(
                period.label(now, financialYearStartMonth: startMonth),
              ),
            ),
        ],
        onChanged: (period) {
          if (period != null) onChanged(period);
        },
      ),
    );
  }
}
