import 'package:billing_guru/features/sales/domain/sales_period.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Monday 19 Oct 2026.
  final now = DateTime(2026, 10, 21, 14, 30);

  test('week runs Monday to the next Monday', () {
    final range = SalesPeriod.week.rangeFor(now)!;
    expect(range.from, DateTime(2026, 10, 19));
    expect(range.to, DateTime(2026, 10, 26));
  });

  test('month and quarter (April financial year)', () {
    final month = SalesPeriod.month.rangeFor(now)!;
    expect(month.from, DateTime(2026, 10));
    expect(month.to, DateTime(2026, 11));

    final quarter = SalesPeriod.quarter.rangeFor(now)!;
    expect(quarter.from, DateTime(2026, 10));
    expect(quarter.to, DateTime(2027, 1));

    final february = SalesPeriod.quarter.rangeFor(DateTime(2027, 2, 10))!;
    expect(february.from, DateTime(2027, 1));
    expect(february.to, DateTime(2027, 4));
  });

  test('financial years', () {
    final current = SalesPeriod.financialYear.rangeFor(now)!;
    expect(current.from, DateTime(2026, 4));
    expect(current.to, DateTime(2027, 4));

    final earlyYear = SalesPeriod.financialYear.rangeFor(DateTime(2027, 2, 1))!;
    expect(earlyYear.from, DateTime(2026, 4));

    final previous = SalesPeriod.previousFinancialYear.rangeFor(now)!;
    expect(previous.from, DateTime(2025, 4));
    final older = SalesPeriod.twoYearsAgoFinancialYear.rangeFor(now)!;
    expect(older.from, DateTime(2024, 4));
    expect(older.to, DateTime(2025, 4));
  });

  test('labels and calendar financial year', () {
    expect(SalesPeriod.financialYear.label(now), 'FY 2026-27 (current)');
    expect(SalesPeriod.previousFinancialYear.label(now), 'FY 2025-26');
    expect(
      SalesPeriod.previousFinancialYear.label(now, financialYearStartMonth: 1),
      'FY 2025',
    );
    expect(SalesPeriod.all.rangeFor(now), isNull);
  });
}
