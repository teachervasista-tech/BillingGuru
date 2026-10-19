import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const financialYearStartAssetPath = 'assets/config/financial_year_start.txt';

/// Month number (1-12) in which the financial year starts. Read from
/// assets/config/financial_year_start.txt; defaults to April.
final financialYearStartMonthProvider = FutureProvider<int>((ref) async {
  try {
    final value = int.tryParse(
      (await rootBundle.loadString(financialYearStartAssetPath)).trim(),
    );
    return value != null && value >= 1 && value <= 12 ? value : 4;
  } catch (_) {
    return 4;
  }
});

/// Half-open date range: [from, to).
class SalesDateRange {
  const SalesDateRange(this.from, this.to);

  final DateTime from;
  final DateTime to;
}

enum SalesPeriod {
  all,
  week,
  month,
  quarter,
  financialYear,
  previousFinancialYear,
  twoYearsAgoFinancialYear;

  int get _financialYearsBack => switch (this) {
    SalesPeriod.previousFinancialYear => 1,
    SalesPeriod.twoYearsAgoFinancialYear => 2,
    _ => 0,
  };

  SalesDateRange? rangeFor(DateTime now, {int financialYearStartMonth = 4}) {
    final startYear = now.month >= financialYearStartMonth
        ? now.year
        : now.year - 1;

    switch (this) {
      case SalesPeriod.all:
        return null;
      case SalesPeriod.week:
        final monday = DateTime(
          now.year,
          now.month,
          now.day - (now.weekday - 1),
        );
        return SalesDateRange(
          monday,
          DateTime(monday.year, monday.month, monday.day + 7),
        );
      case SalesPeriod.month:
        return SalesDateRange(
          DateTime(now.year, now.month),
          DateTime(now.year, now.month + 1),
        );
      case SalesPeriod.quarter:
        // Quarters are counted from the start of the financial year.
        final monthsIntoYear = (now.month - financialYearStartMonth + 12) % 12;
        final firstMonth = financialYearStartMonth + (monthsIntoYear ~/ 3) * 3;
        return SalesDateRange(
          DateTime(startYear, firstMonth),
          DateTime(startYear, firstMonth + 3),
        );
      case SalesPeriod.financialYear:
      case SalesPeriod.previousFinancialYear:
      case SalesPeriod.twoYearsAgoFinancialYear:
        final year = startYear - _financialYearsBack;
        return SalesDateRange(
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
      SalesPeriod.all => 'All',
      SalesPeriod.week => 'This week',
      SalesPeriod.month => 'This month',
      SalesPeriod.quarter => 'This quarter',
      SalesPeriod.financialYear => '${fy(0)} (current)',
      SalesPeriod.previousFinancialYear => fy(1),
      SalesPeriod.twoYearsAgoFinancialYear => fy(2),
    };
  }
}
