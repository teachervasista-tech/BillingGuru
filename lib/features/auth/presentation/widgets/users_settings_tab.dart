import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/widgets/section_card.dart';
import '../../data/user_service.dart';
import '../auth_providers.dart';
import 'user_dialogs.dart';

final usersProvider = FutureProvider<List<AppUser>>((ref) {
  return ref.watch(userServiceProvider).getUsers();
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
              'Sellers can ring up sales, look up products, stock and sales '
              'history, and manage customers. Only admins can open Settings, '
              'Expenses and Reports, edit products or stock, and void or '
              'return sales.',
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
                      backgroundColor: user.isAdmin
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      child: Icon(
                        user.isAdmin
                            ? Icons.admin_panel_settings_outlined
                            : Icons.person_outline,
                      ),
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
                        if (user.id != me?.id) ...[
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
