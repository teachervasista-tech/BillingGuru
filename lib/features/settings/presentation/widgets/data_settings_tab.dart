import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/data_refresh.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../core/backup/backup_service.dart';
import '../../../../core/config/app_info.dart';
import '../../../../core/database/database_provider.dart';

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(database: ref.watch(appDatabaseProvider));
});

final databaseLocationProvider = FutureProvider<String>((ref) {
  return ref.watch(appDatabaseProvider).databasePath;
});

/// Settings → Data: backup and restore.
class DataSettingsTab extends ConsumerStatefulWidget {
  const DataSettingsTab({super.key});

  @override
  ConsumerState<DataSettingsTab> createState() => _DataSettingsTabState();
}

class _DataSettingsTabState extends ConsumerState<DataSettingsTab> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      _message('$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _message(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _backup() => _run(() async {
    final stamp = DateFormat('yyyyMMdd-HHmm').format(DateTime.now());
    final location = await getSaveLocation(
      suggestedName: 'billing-guru-backup-$stamp.zip',
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup', extensions: ['zip']),
      ],
    );
    if (location == null) return;
    final bytes = await ref.read(backupServiceProvider).createArchive();
    await File(location.path).writeAsBytes(bytes, flush: true);
    _message('Backup saved to ${location.path}');
  });

  Future<void> _restore() => _run(() async {
    final file = await openFile(
      acceptedTypeGroups: const [
        XTypeGroup(label: 'Backup', extensions: ['zip']),
      ],
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final service = ref.read(backupServiceProvider);
    final manifest = service.inspect(bytes);
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore backup?'),
        content: Text(
          'Backup from '
          '${DateFormat.yMMMd().add_Hm().format(manifest.createdAt)} '
          '(version ${manifest.appVersion}).\n\n'
          'All current products, sales, expenses, customers, settings and '
          'attachments will be replaced. Create a backup first if you may '
          'need the current data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Replace my data'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await service.restoreArchive(bytes);
    await refreshAllData(ref);
    _message('Backup restored.');
  });

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(databaseLocationProvider).value;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Backup',
          description:
              'Saves products, sales, expenses, customers, settings, product '
              'images and expense receipts into one .zip file. Keep a copy on '
              'a USB drive or cloud folder.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: _busy ? null : _backup,
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Create backup'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Restore',
          description:
              'Replaces all current data with a backup. Use this to move to a '
              'new computer or recover from a problem.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _restore,
              icon: const Icon(Icons.restore),
              label: const Text('Restore from backup'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'About',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${AppInfo.name} ${AppInfo.version}'),
              if (location != null) ...[
                const SizedBox(height: 4),
                SelectableText(
                  'Database: $location',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
        if (_busy) ...[
          const SizedBox(height: 16),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }
}
