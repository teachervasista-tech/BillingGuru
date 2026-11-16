import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/data_refresh.dart';
import '../../../../app/widgets/section_card.dart';
import '../../../../core/backup/backup_providers.dart';
import '../../../../core/config/app_info.dart';
import '../../../../core/database/database_provider.dart';
import '../../../auth/presentation/auth_providers.dart';

export '../../../../core/backup/backup_providers.dart';

final databaseLocationProvider = FutureProvider<String>((ref) {
  return ref.watch(appDatabaseProvider).databasePath;
});

final _defaultBackupFolderProvider = FutureProvider<String>((ref) async {
  return (await ref.watch(autoBackupServiceProvider).defaultFolder()).path;
});

/// Settings → Data: automatic backups, manual backup and restore.
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

  Future<void> _backupNow() => _run(() async {
    final status = await ref.read(autoBackupServiceProvider).run();
    ref.invalidate(autoBackupStatusProvider);
    _message(
      status.lastError ??
          'Backup saved to ${status.lastPath ?? 'backup folder'}',
    );
  });

  Future<void> _chooseFolder() => _run(() async {
    final folder = await getDirectoryPath(confirmButtonText: 'Use this folder');
    if (folder == null) return;
    await ref.read(autoBackupServiceProvider).setFolder(folder);
    ref.invalidate(autoBackupStatusProvider);
    _message('Backups will be saved to $folder');
  });

  Future<void> _useLocalFolder() => _run(() async {
    await ref.read(autoBackupServiceProvider).setFolder(null);
    ref.invalidate(autoBackupStatusProvider);
  });

  Future<void> _saveCopyAs() => _run(() async {
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
    final status = ref.watch(autoBackupStatusProvider).value;
    final defaultFolder = ref.watch(_defaultBackupFolderProvider).value;
    final canConfigure =
        ref.watch(currentUserProvider)?.can(Permission.configureSystem) ??
        false;
    final textTheme = Theme.of(context).textTheme;
    final folder = status?.folder ?? defaultFolder;
    final lastAt = status?.lastAt;

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Automatic backup',
          description:
              'A backup of all data (products, sales, expenses, customers, '
              'settings, images and receipts) is made every day when the app '
              'starts and again when it is closed. The last 30 days are kept. '
              'Choose a folder on a USB drive, network drive or a cloud-synced '
              'folder (OneDrive, Google Drive) so the data survives if this '
              'computer fails.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Backup folder', style: textTheme.labelLarge),
              const SizedBox(height: 4),
              SelectableText(folder ?? '…', key: const Key('backupFolder')),
              if (status?.folder == null) ...[
                const SizedBox(height: 4),
                Text(
                  'This folder is on this computer. Choose a USB, network or '
                  'cloud folder for protection against computer failure.',
                  style: textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text('Last backup', style: textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(
                lastAt == null
                    ? 'No backup yet'
                    : DateFormat.yMMMd().add_Hm().format(lastAt),
                key: const Key('lastBackup'),
              ),
              if (status?.lastPath case final String path)
                SelectableText(path, style: textTheme.bodySmall),
              if (status?.lastError case final String error) ...[
                const SizedBox(height: 8),
                Text(
                  error,
                  style: textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    key: const Key('backupNow'),
                    onPressed: _busy ? null : _backupNow,
                    icon: const Icon(Icons.backup_outlined),
                    label: const Text('Back up now'),
                  ),
                  if (canConfigure) ...[
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _chooseFolder,
                      icon: const Icon(Icons.folder_open_outlined),
                      label: const Text('Choose backup folder'),
                    ),
                    if (status?.folder != null)
                      TextButton(
                        onPressed: _busy ? null : _useLocalFolder,
                        child: const Text('Use this computer'),
                      ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          title: 'Save a copy',
          description:
              'Saves a backup .zip file wherever you choose, e.g. to move the '
              'data to a new computer.',
          child: Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _saveCopyAs,
              icon: const Icon(Icons.save_alt),
              label: const Text('Save backup as…'),
            ),
          ),
        ),
        if (canConfigure) ...[
          const SizedBox(height: 16),
          SectionCard(
            title: 'Restore',
            description:
                'Replaces all current data with a backup. Use this to move to '
                'a new computer or recover from a problem.',
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _restore,
                icon: const Icon(Icons.restore),
                label: const Text('Restore from backup'),
              ),
            ),
          ),
        ],
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
                  style: textTheme.bodySmall,
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
