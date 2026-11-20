import 'package:flutter/services.dart';

import '../config/app_features.dart';
import 'business_details.dart';

export 'business_details.dart';

/// Runtime-editable application settings.
///
/// Values start from the bundled `assets/config/*` files (first-run defaults)
/// and are overridden by whatever the user saved in Settings.
class AppSettings {
  const AppSettings({
    this.business = const BusinessDetails(),
    this.currencyCode = 'EUR',
    this.invoiceSequence = 'DAILY',
    this.financialYearStartMonth = 4,
    this.lowStockThreshold = 10,
    this.colorThemeId = 'blue',
    this.features = const AppFeatures(),
    this.receiptLogoSource = 'default',
    this.receiptLogoStyle = 'blackAndWhite',
  });

  /// Business name, address, phone and tax ID printed on receipts.
  final BusinessDetails business;
  final String currencyCode;

  /// DAILY, MONTHLY or YEARLY.
  final String invoiceSequence;
  final int financialYearStartMonth;
  final int lowStockThreshold;
  final String colorThemeId;
  final AppFeatures features;

  /// `default` (bundled logo), `custom` (uploaded) or `none`.
  final String receiptLogoSource;

  /// `LogoPrintStyle` name used to convert an uploaded logo.
  final String receiptLogoStyle;

  static const fallback = AppSettings();

  /// Old free-text receipt header; only read, to migrate it to [business].
  static const keyBusinessDetails = 'business_details';
  static const keyCurrency = 'currency_code';
  static const keyInvoiceSequence = 'invoice_sequence';
  static const keyFinancialYearStart = 'financial_year_start_month';
  static const keyLowStockThreshold = 'low_stock_threshold';
  static const keyColorTheme = 'color_theme';
  static const featurePrefix = 'feature.';
  static const keyReceiptLogoSource = 'receipt_logo_source';
  static const keyReceiptLogoStyle = 'receipt_logo_style';

  String get businessName => business.displayName;

  /// Receipt header lines, business name first.
  String get businessDetails => business.receiptText;

  AppSettings copyWith({
    BusinessDetails? business,
    String? currencyCode,
    String? invoiceSequence,
    int? financialYearStartMonth,
    int? lowStockThreshold,
    String? colorThemeId,
    AppFeatures? features,
    String? receiptLogoSource,
    String? receiptLogoStyle,
  }) {
    return AppSettings(
      business: business ?? this.business,
      currencyCode: currencyCode ?? this.currencyCode,
      invoiceSequence: invoiceSequence ?? this.invoiceSequence,
      financialYearStartMonth:
          financialYearStartMonth ?? this.financialYearStartMonth,
      lowStockThreshold: lowStockThreshold ?? this.lowStockThreshold,
      colorThemeId: colorThemeId ?? this.colorThemeId,
      features: features ?? this.features,
      receiptLogoSource: receiptLogoSource ?? this.receiptLogoSource,
      receiptLogoStyle: receiptLogoStyle ?? this.receiptLogoStyle,
    );
  }

  Map<String, String> toStore() {
    return {
      ...business.toStore(),
      keyCurrency: currencyCode,
      keyInvoiceSequence: invoiceSequence,
      keyFinancialYearStart: '$financialYearStartMonth',
      keyLowStockThreshold: '$lowStockThreshold',
      keyColorTheme: colorThemeId,
      keyReceiptLogoSource: receiptLogoSource,
      keyReceiptLogoStyle: receiptLogoStyle,
      for (final key in AppFeatures.allKeys)
        '$featurePrefix$key': '${features.isEnabled(key)}',
    };
  }

  /// Applies saved values on top of these (default) settings. Invalid saved
  /// values are ignored.
  AppSettings applyStored(Map<String, String> stored) {
    int? intIn(String key, int min, int max) {
      final value = int.tryParse(stored[key] ?? '');
      return value != null && value >= min && value <= max ? value : null;
    }

    return copyWith(
      business: BusinessDetails.isStoredIn(stored)
          ? BusinessDetails.fromStore(stored)
          : switch (stored[keyBusinessDetails]) {
              final legacy? => BusinessDetails.fromLegacyText(legacy),
              null => null,
            },
      currencyCode: stored[keyCurrency],
      invoiceSequence: stored[keyInvoiceSequence],
      financialYearStartMonth: intIn(keyFinancialYearStart, 1, 12),
      lowStockThreshold: intIn(keyLowStockThreshold, 0, 1000000),
      colorThemeId: stored[keyColorTheme],
      receiptLogoSource: stored[keyReceiptLogoSource],
      receiptLogoStyle: stored[keyReceiptLogoStyle],
      features: features.merge({
        for (final key in AppFeatures.allKeys)
          if (stored['$featurePrefix$key'] case final value?)
            key: value == 'true',
      }),
    );
  }

  /// Reads the bundled config files. Each missing/invalid file falls back to
  /// [fallback]'s value.
  static Future<AppSettings> loadAssetDefaults({
    AssetBundle? bundle,
    String? colorThemeId,
  }) async {
    final assets = bundle ?? rootBundle;

    Future<String?> read(String name) async {
      try {
        final text = (await assets.loadString('assets/config/$name')).trim();
        return text.isEmpty ? null : text;
      } catch (_) {
        return null;
      }
    }

    final fyStart = int.tryParse(await read('financial_year_start.txt') ?? '');

    return fallback.copyWith(
      business: switch (await read('receipt_business_details.txt')) {
        final text? => BusinessDetails.fromLegacyText(text),
        null => null,
      },
      currencyCode: await read('currency.txt'),
      invoiceSequence: await read('invoice_sequence.txt'),
      financialYearStartMonth: fyStart != null && fyStart >= 1 && fyStart <= 12
          ? fyStart
          : null,
      colorThemeId: colorThemeId,
      features: AppFeatures.instance,
    );
  }
}
