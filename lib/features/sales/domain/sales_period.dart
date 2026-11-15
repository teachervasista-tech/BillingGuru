import '../../../core/period/date_range.dart';

export '../../../core/period/date_range.dart';
export '../../../core/settings/app_settings_provider.dart'
    show financialYearStartMonthProvider;

/// Kept for backwards compatibility; use [DateRange] in new code.
typedef SalesDateRange = DateRange;

/// Kept for backwards compatibility; use [PeriodPreset] in new code.
typedef SalesPeriod = PeriodPreset;
