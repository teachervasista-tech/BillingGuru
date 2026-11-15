import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/printing/receipt_paper_size.dart';
import '../core/printing/receipt_template_provider.dart';
import '../core/settings/app_settings_provider.dart';
import '../core/tax/tax_rate_provider.dart';
import '../features/checkout/presentation/providers/payment_options_provider.dart';
import '../features/customers/presentation/customer_providers.dart';
import '../features/dashboard/presentation/view_models/dashboard_view_model.dart';
import '../features/expenses/presentation/expense_providers.dart';
import '../features/inventory/presentation/view_models/inventory_view_model.dart';
import '../features/products/presentation/view_models/product_view_model.dart';
import '../features/reports/presentation/providers/report_providers.dart';
import '../features/sales/presentation/view_models/sales_view_model.dart';
import 'theme.dart';

/// Reloads settings and every data-backed provider, e.g. after restoring a
/// backup, so the UI reflects the new database without a restart.
Future<void> refreshAllData(WidgetRef ref) async {
  await ref
      .read(appSettingsProvider.notifier)
      .load(defaultColorThemeId: AppColorTheme.selected.id);
  await ref.read(defaultTaxRateProvider.notifier).loadSavedTaxRate();
  await ref.read(receiptTemplateProvider.notifier).loadSavedTemplate();

  ref.invalidate(receiptPaperSizeProvider);
  ref.invalidate(paymentOptionsProvider);
  ref.invalidate(productViewModelProvider);
  ref.invalidate(inventoryViewModelProvider);
  ref.invalidate(salesViewModelProvider);
  ref.invalidate(saleItemsProvider);
  ref.invalidate(dashboardViewModelProvider);
  ref.invalidate(reportProvider);
  ref.invalidate(expensesViewModelProvider);
  ref.invalidate(expenseCategoriesProvider);
  ref.invalidate(recurringExpensesProvider);
  ref.invalidate(customersProvider);
  ref.invalidate(customerStatsProvider);
  ref.invalidate(customerSalesProvider);
}
