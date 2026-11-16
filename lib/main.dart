import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/auto_backup_on_exit.dart';
import 'app/theme.dart';
import 'core/backup/backup_providers.dart';
import 'core/config/app_features.dart';
import 'core/database/app_database.dart';
import 'core/database/database_initializer.dart';
import 'core/printing/receipt_template_provider.dart';
import 'core/settings/app_settings_provider.dart';
import 'core/tax/tax_rate_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppFeatures.load();
  await AppColorTheme.load();

  await initializeDatabase();
  await AppDatabase.instance.database;

  final container = ProviderContainer();

  await container
      .read(appSettingsProvider.notifier)
      .load(defaultColorThemeId: AppColorTheme.selected.id);
  await Future.wait([
    container.read(receiptTemplateProvider.notifier).loadSavedTemplate(),
    container.read(defaultTaxRateProvider.notifier).loadSavedTaxRate(),
  ]);

  // Daily backup in the background; never delays startup.
  unawaited(container.read(autoBackupServiceProvider).runIfDue());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const AutoBackupOnExit(child: BillingGuru()),
    ),
  );
}
