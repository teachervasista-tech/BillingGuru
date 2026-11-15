import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/widgets/section_card.dart';
import '../../data/user_service.dart';
import '../auth_providers.dart';
import 'user_dialogs.dart';

/// Accounts shown in Settings → Users. The installer account is only
/// listed for the installer.
final usersProvider = FutureProvider<List<AppUser>>((ref) {
  final me = ref.watch(currentUserProvider);
  return ref
      .watch(userServiceProvider)
      .getUsers(includeInstaller: me?.isInstaller ?? false);
});

/// Settings → Users (admin only): create sellers/admins, reset passwords,
/// change roles and disable accounts.
class UsersSettingsTab extends ConsumerWidget {
  const UsersSettingsTab({super.key});

  Future<void> _guard(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
    String success,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
      ref.invalidate(usersProvider);
      messenger.showSnackBar(SnackBar(content: Text(success)));
    } on AuthException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersProvider);
    final me = ref.watch(currentUserProvider);
    final service = ref.read(userServiceProvider);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SectionCard(
          title: 'Users',
          description:
              'Admins run the shop: products and stock, expenses, reports, '
              'voids and returns, users and categories. Sellers ring up sales, '
              'look up products, stock and sales history, and manage '
              'customers; they have no access to Settings.',
          trailing: FilledButton.icon(
            key: const Key('addUserButton'),
            onPressed: () async {
              final created = await showDialog<bool>(
                context: context,
                builder: (_) => const AddUserDialog(),
              );
              if (created == true) ref.invalidate(usersProvider);
            },
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Add user'),
          ),
          child: usersAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, _) => Text('$error'),
            data: (users) => Column(
              children: [
                for (final user in users)
                  ListTile(
                    key: Key('user-${user.username}'),
                    leading: CircleAvatar(
                      backgroundColor: !user.isAdmin && !user.isInstaller
                          ? null
                          : user.isAdmin
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.tertiaryContainer,
                      child: Icon(switch (user.role) {
                        UserRole.installer => Icons.build_outlined,
                        UserRole.admin => Icons.admin_panel_settings_outlined,
                        UserRole.seller => Icons.person_outline,
                      }),
                    ),
                    title: Text(
                      '${user.displayName}'
                      '${user.id == me?.id ? '  (you)' : ''}',
                      style: user.isActive
                          ? null
                          : const TextStyle(
                              decoration: TextDecoration.lineThrough,
                            ),
                    ),
                    subtitle: Text(
                      '@${user.username} · ${user.role.label}'
                      '${user.isActive ? '' : ' · disabled'}'
                      '${user.lastLoginAt == null ? '' : ' · last sign-in ${DateFormat.yMMMd().add_Hm().format(user.lastLoginAt!)}'}',
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Manage ${user.displayName}',
                      onSelected: (value) async {
                        switch (value) {
                          case 'password':
                            final result = await showDialog<(String, String)>(
                              context: context,
                              builder: (_) => PasswordDialog(
                                title: 'Reset password for ${user.displayName}',
                              ),
                            );
                            if (result != null && context.mounted) {
                              await _guard(
                                context,
                                ref,
                                () => service.setPassword(user.id, result.$2),
                                'Password reset',
                              );
                            }
                          case 'role':
                            final role = user.isAdmin
                                ? UserRole.seller
                                : UserRole.admin;
                            await _guard(
                              context,
                              ref,
                              () => service.updateUser(user.id, role: role),
                              '${user.displayName} is now ${role.label}',
                            );
                          case 'active':
                            await _guard(
                              context,
                              ref,
                              () => service.updateUser(
                                user.id,
                                isActive: !user.isActive,
                              ),
                              user.isActive
                                  ? '${user.displayName} disabled'
                                  : '${user.displayName} enabled',
                            );
                        }
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(
                          value: 'password',
                          child: Text('Reset password'),
                        ),
                        if (user.id != me?.id && !user.isInstaller) ...[
                          PopupMenuItem(
                            value: 'role',
                            child: Text(
                              user.isAdmin ? 'Make seller' : 'Make admin',
                            ),
                          ),
                          PopupMenuItem(
                            value: 'active',
                            child: Text(user.isActive ? 'Disable' : 'Enable'),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
