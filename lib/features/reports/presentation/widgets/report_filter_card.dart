import 'package:flutter/material.dart';

import '../providers/report_providers.dart';

class ReportFilterCard extends StatelessWidget {
  const ReportFilterCard({
    required this.selectedType,
    required this.selectedRange,
    required this.label,
    required this.onPeriodChanged,
    required this.onCustomRangePressed,
    super.key,
  });

  final ReportPeriodType selectedType;
  final DateTimeRange? selectedRange;
  final String label;
  final ValueChanged<ReportPeriodType> onPeriodChanged;
  final VoidCallback onCustomRangePressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_alt_outlined, color: colorScheme.primary),
                const SizedBox(width: 10),
                Text(
                  'Report period',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Choose the period used for the sales reports.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _ReportPeriodChip(
                  label: 'Today',
                  selected: selectedType == ReportPeriodType.today,
                  onSelected: (_) {
                    onPeriodChanged(ReportPeriodType.today);
                  },
                ),

                _ReportPeriodChip(
                  label: 'This month',
                  selected: selectedType == ReportPeriodType.thisMonth,
                  onSelected: (_) {
                    onPeriodChanged(ReportPeriodType.thisMonth);
                  },
                ),
                _ReportPeriodChip(
                  label: 'Custom range',
                  selected: selectedType == ReportPeriodType.today,
                  onSelected: (_) {
                    onCustomRangePressed();
                  },
                ),
              ],
            ),
            if (selectedType == ReportPeriodType.last7Days) ...[
              const SizedBox(height: 16),
              _DateRangeField(
                label: label,
                hasValue: selectedRange != null,
                onTap: onCustomRangePressed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportPeriodChip extends StatelessWidget {
  const _ReportPeriodChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: true,
      avatar: selected
          ? null
          : const Icon(Icons.calendar_today_outlined, size: 18),
      onSelected: onSelected,
    );
  }
}

class _DateRangeField extends StatelessWidget {
  const _DateRangeField({
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Date range',
          prefixIcon: Icon(Icons.date_range),
          suffixIcon: Icon(Icons.calendar_month),
          border: OutlineInputBorder(),
        ),
        child: Text(
          hasValue ? label : 'Select start and end dates',
          style: TextStyle(
            color: hasValue
                ? colorScheme.onSurface
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
