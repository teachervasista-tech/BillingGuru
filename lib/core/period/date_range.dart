/// Half-open date range: [from, to).
///
/// Dates are stored in the database as local ISO-8601 strings, which sort
/// lexically, so a range maps directly to `created_at >= ? AND created_at < ?`.
class DateRange {
  const DateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;

  /// Query arguments for a `col >= ? AND col < ?` clause.
  List<String> get sqlArgs => [from.toIso8601String(), to.toIso8601String()];

  bool contains(DateTime value) => !value.isBefore(from) && value.isBefore(to);

  /// Builds `"<column> >= ? AND <column> < ?"`.
  static String sqlClause(String column) => '$column >= ? AND $column < ?';

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'DateRange($from, $to)';
}

/// Reusable period presets shared by sales history, reports and expenses.
enum PeriodPreset {
  all,
  today,
  last7Days,
  week,
  month,
  lastMonth,
  quarter,
  financialYear,
  previousFinancialYear,
  twoYearsAgoFinancialYear;

  int get _financialYearsBack => switch (this) {
    PeriodPreset.previousFinancialYear => 1,
    PeriodPreset.twoYearsAgoFinancialYear => 2,
    _ => 0,
  };

  /// Returns null for [PeriodPreset.all] (no date filter).
  DateRange? rangeFor(DateTime now, {int financialYearStartMonth = 4}) {
    final startYear = now.month >= financialYearStartMonth
        ? now.year
        : now.year - 1;
    final todayStart = DateTime(now.year, now.month, now.day);

    switch (this) {
      case PeriodPreset.all:
        return null;
      case PeriodPreset.today:
        return DateRange(
          todayStart,
          DateTime(now.year, now.month, now.day + 1),
        );
      case PeriodPreset.last7Days:
        final end = DateTime(now.year, now.month, now.day + 1);
        return DateRange(DateTime(end.year, end.month, end.day - 7), end);
      case PeriodPreset.week:
        final monday = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        return DateRange(
          monday,
          DateTime(monday.year, monday.month, monday.day + 7),
        );
      case PeriodPreset.month:
        return DateRange(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        );
      case PeriodPreset.lastMonth:
        return DateRange(
          DateTime(now.year, now.month - 1),
          DateTime(now.year, now.month),
        );
      case PeriodPreset.quarter:
        // Quarters are counted from the start of the financial year.
        final monthsIntoYear = (now.month - financialYearStartMonth + 12) % 12;
        final firstMonth = financialYearStartMonth + (monthsIntoYear ~/ 3) * 3;
        return DateRange(
          DateTime(startYear, firstMonth),
          DateTime(startYear, firstMonth + 3),
        );
      case PeriodPreset.financialYear:
      case PeriodPreset.previousFinancialYear:
      case PeriodPreset.twoYearsAgoFinancialYear:
        final year = startYear - _financialYearsBack;
        return DateRange(
          DateTime(year, financialYearStartMonth),
          DateTime(year + 1, financialYearStartMonth),
        );
    }
  }

  String label(DateTime now, {int financialYearStartMonth = 4}) {
    String fy(int back) {
      final start =
          (now.month >= financialYearStartMonth ? now.year : now.year - 1) -
          back;
      if (financialYearStartMonth == 1) return 'FY $start';
      return 'FY $start-${((start + 1) % 100).toString().padLeft(2, '0')}';
    }

    return switch (this) {
      PeriodPreset.all => 'All',
      PeriodPreset.today => 'Today',
      PeriodPreset.last7Days => 'Last 7 days',
      PeriodPreset.week => 'This week',
      PeriodPreset.month => 'This month',
      PeriodPreset.lastMonth => 'Last month',
      PeriodPreset.quarter => 'This quarter',
      PeriodPreset.financialYear => '${fy(0)} (current)',
      PeriodPreset.previousFinancialYear => fy(1),
      PeriodPreset.twoYearsAgoFinancialYear => fy(2),
    };
  }
}
