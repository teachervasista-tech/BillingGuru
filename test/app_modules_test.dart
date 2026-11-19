import 'package:billing_guru/app/modules.dart';
import 'package:billing_guru/core/config/app_features.dart';
import 'package:billing_guru/core/period/date_range.dart';
import 'package:billing_guru/core/settings/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

void main() {
  group('moduleRouteRedirect', () {
    test('allows enabled modules', () {
      expect(
        moduleRouteRedirect('/sales', const AppFeatures(), testAdmin),
        isNull,
      );
    });

    test('redirects disabled modules and their sub-routes', () {
      const features = AppFeatures({AppFeatures.pos: false});
      expect(moduleRouteRedirect('/pos', features, testAdmin), '/home');
      expect(moduleRouteRedirect('/checkout', features, testAdmin), '/home');
    });

    test('dashboard is on by default and can be switched off', () {
      expect(
        moduleRouteRedirect('/dashboard', const AppFeatures(), testSeller),
        isNull,
      );
      const off = AppFeatures({AppFeatures.dashboard: false});
      expect(moduleRouteRedirect('/dashboard', off, testSeller), '/home');
    });

    test('with home and dashboard off, users land on the next module', () {
      const features = AppFeatures({
        AppFeatures.home: false,
        AppFeatures.dashboard: false,
      });
      expect(landingRoute(features, testSeller), '/pos');
      expect(moduleRouteRedirect('/dashboard', features, testSeller), '/pos');
    });
  });

  group('AppSettings store round-trip', () {
    test('saved values override defaults; invalid values are ignored', () {
      const defaults = AppSettings(currencyCode: 'INR');
      final saved = defaults
          .copyWith(
            currencyCode: 'USD',
            financialYearStartMonth: 1,
            features: const AppFeatures({AppFeatures.reports: false}),
          )
          .toStore();

      final restored = defaults.applyStored(saved);
      expect(restored.currencyCode, 'USD');
      expect(restored.financialYearStartMonth, 1);
      expect(restored.features.reportsEnabled, isFalse);

      final invalid = defaults.applyStored({
        AppSettings.keyFinancialYearStart: '13',
      });
      expect(invalid.financialYearStartMonth, 4);
    });
  });

  group('PeriodPreset', () {
    final now = DateTime(2026, 11, 15, 14, 30);

    test('today and last 7 days are half-open day ranges', () {
      expect(
        PeriodPreset.today.rangeFor(now),
        DateRange(DateTime(2026, 11, 15), DateTime(2026, 11, 16)),
      );
      expect(
        PeriodPreset.last7Days.rangeFor(now),
        DateRange(DateTime(2026, 11, 9), DateTime(2026, 11, 16)),
      );
    });

    test('last month crosses the year boundary', () {
      expect(
        PeriodPreset.lastMonth.rangeFor(DateTime(2027, 1, 10)),
        DateRange(DateTime(2026, 12), DateTime(2027, 1)),
      );
    });

    test('contains is inclusive of from and exclusive of to', () {
      final range = PeriodPreset.today.rangeFor(now)!;
      expect(range.contains(DateTime(2026, 11, 15)), isTrue);
      expect(range.contains(DateTime(2026, 11, 16)), isFalse);
    });
  });
}
