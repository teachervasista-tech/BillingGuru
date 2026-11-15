import 'package:flutter/services.dart';

import '../config/app_features.dart';

/// Runtime-editable application settings.
///
/// Values start from the bundled `assets/config/*` files (first-run defaults)
/// and are overridden by whatever the user saved in Settings.
class AppSettings {
  const AppSettings({
    this.businessDetails = '',
    this.currencyCode = 'EUR',
    this.invoiceSequence = 'DAILY',
    this.financialYearStartMonth = 4,
    this.lowStockThreshold = 10,
    this.colorThemeId = 'blue',
    this.features = const AppFeatures(),
    this.receiptLogoSource = 'default',
    this.receiptLogoStyle = 'blackAndWhite',
  });

  /// Receipt header: business name on the first line, then address etc.
  final String businessDetails;
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

  static const keyBusinessDetails = 'business_details';
  static const keyCurrency = 'currency_code';
  static const keyInvoiceSequence = 'invoice_sequence';
  static const keyFinancialYearStart = 'financial_year_start_month';
  static const keyLowStockThreshold = 'low_stock_threshold';
  static const keyColorTheme = 'color_theme';
  static const featurePrefix = 'feature.';
  static const keyReceiptLogoSource = 'receipt_logo_source';
  static const keyReceiptLogoStyle = 'receipt_logo_style';

  String get businessName {
    final first = businessDetails.split('\n').first.trim();
    return first.isEmpty ? 'Billing Guru' : first;
  }

  AppSettings copyWith({
    String? businessDetails,
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
      businessDetails: businessDetails ?? this.businessDetails,
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
      keyBusinessDetails: businessDetails,
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
      businessDetails: stored[keyBusinessDetails],
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
      businessDetails: await read('receipt_business_details.txt'),
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
