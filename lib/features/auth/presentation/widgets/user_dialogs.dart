import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/user_service.dart';
import '../auth_providers.dart';

/// Admin: create an account. Returns true when created.
class AddUserDialog extends ConsumerStatefulWidget {
  const AddUserDialog({super.key});

  @override
  ConsumerState<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends ConsumerState<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  UserRole _role = UserRole.seller;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    for (final c in [_name, _username, _password]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(userServiceProvider)
          .createUser(
            username: _username.text,
            displayName: _name.text,
            password: _password.text,
            role: _role,
          );
      if (mounted) Navigator.pop(context, true);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add user'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<UserRole>(
                segments: [
                  for (final role in UserRole.assignable)
                    ButtonSegment(value: role, label: Text(role.label)),
                ],
                selected: {_role},
                onSelectionChanged: (s) => setState(() => _role = s.first),
              ),
              const SizedBox(height: 8),
              Text(
                _role == UserRole.seller
                    ? 'Sellers can sell, view products, stock and sales, and '
                          'manage customers.'
                    : 'Admins run the shop: products, stock, expenses, '
                          'reports, voids, users and categories.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('newUserName'),
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('newUserUsername'),
                controller: _username,
                decoration: const InputDecoration(labelText: 'Username'),
                validator: UserService.validateUsername,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('newUserPassword'),
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Initial password',
                  helperText: 'They can change it after signing in.',
                ),
                validator: UserService.validatePassword,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          key: const Key('createUserButton'),
          onPressed: _busy ? null : _save,
          child: const Text('Create user'),
        ),
      ],
    );
  }
}

/// New-password prompt. With [requireCurrent] the user must also enter
/// their current password (self-service change). Pops
/// `(current, new)` or null.
class PasswordDialog extends StatefulWidget {
  const PasswordDialog({
    required this.title,
    this.requireCurrent = false,
    super.key,
  });

  final String title;
  final bool requireCurrent;

  @override
  State<PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<PasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    for (final c in [_current, _password, _confirm]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 360,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.requireCurrent) ...[
                TextFormField(
                  controller: _current,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                  validator: (v) => (v ?? '').isEmpty ? 'Required.' : null,
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _password,
                obscureText: true,
                autofocus: !widget.requireCurrent,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: UserService.validatePassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirm,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm new password',
                ),
                validator: (v) =>
                    v != _password.text ? 'Passwords do not match.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, (_current.text, _password.text));
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Account button for the navigation rail: shows who is signed in and
/// offers "Change password" and "Sign out".
class UserMenuButton extends ConsumerWidget {
  const UserMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      key: const Key('userMenu'),
      tooltip: '${user.displayName} (${user.role.label})',
      onSelected: (value) async {
        if (value == 'logout') {
          ref.read(authProvider.notifier).logout();
        } else if (value == 'password') {
          final result = await showDialog<(String, String)>(
            context: context,
            builder: (_) => const PasswordDialog(
              title: 'Change my password',
              requireCurrent: true,
            ),
          );
          if (result == null || !context.mounted) return;
          final messenger = ScaffoldMessenger.of(context);
          try {
            await ref
                .read(userServiceProvider)
                .changeOwnPassword(user, result.$1, result.$2);
            messenger.showSnackBar(
              const SnackBar(content: Text('Password changed')),
            );
          } on AuthException catch (error) {
            messenger.showSnackBar(SnackBar(content: Text(error.message)));
          }
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('${user.displayName}\n${user.role.label}'),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'password',
          child: ListTile(
            leading: Icon(Icons.key_outlined),
            title: Text('Change password'),
          ),
        ),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out')),
        ),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          children: [
            CircleAvatar(
              child: Text(user.displayName.characters.first.toUpperCase()),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 72,
              child: Text(
                user.displayName,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
