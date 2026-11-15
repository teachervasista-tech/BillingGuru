import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_info.dart';
import '../../../../core/database/migrations.dart';
import '../../../../core/settings/app_settings_provider.dart';
import '../../data/user_service.dart';
import '../auth_providers.dart';

/// Centered card used by the login and first-run setup screens.
class _AuthCard extends ConsumerWidget {
  const _AuthCard({required this.title, required this.child, this.subtitle});

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final business = ref.watch(
      appSettingsProvider.select((s) => s.businessName),
    );

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(
                      Icons.point_of_sale,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      business,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    child,
                    const SizedBox(height: 16),
                    Text(
                      '${AppInfo.name} ${AppInfo.version}',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _busy = false;
  bool _obscure = true;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .login(_username.text, _password.text);
    } on AuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message);
        _password.clear();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AuthCard(
      title: 'Sign in',
      subtitle: ref.watch(isFirstUseProvider).value == true
          ? 'First time? Sign in as "$installerUsername" with password '
                '"$installerDefaultPassword" to set up the shop.'
          : null,
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('loginUsername'),
                controller: _username,
                autofocus: true,
                autofillHints: const [AutofillHints.username],
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter your username.' : null,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const Key('loginPassword'),
                controller: _password,
                obscureText: _obscure,
                autofillHints: const [AutofillHints.password],
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                validator: (v) =>
                    (v ?? '').isEmpty ? 'Enter your password.' : null,
                onFieldSubmitted: (_) => _submit(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton.icon(
                key: const Key('loginButton'),
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shown after sign-in when the account still has a default password
/// (the installer on first use).
class RequiredPasswordChangeScreen extends ConsumerStatefulWidget {
  const RequiredPasswordChangeScreen({super.key});

  @override
  ConsumerState<RequiredPasswordChangeScreen> createState() =>
      _RequiredPasswordChangeScreenState();
}

class _RequiredPasswordChangeScreenState
    extends ConsumerState<RequiredPasswordChangeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    if (_password.text == installerDefaultPassword) {
      setState(() => _error = 'Choose a password other than the default.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(authProvider.notifier)
          .completeRequiredPasswordChange(_password.text);
    } on AuthException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    return _AuthCard(
      title: 'Set a new password',
      subtitle:
          '${user?.displayName ?? 'This account'} still uses the default '
          'password. Choose a new one to continue — keep it safe, it cannot '
          'be recovered.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('newPassword'),
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'New password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: UserService.validatePassword,
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('confirmPassword'),
              controller: _confirm,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm new password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
              validator: (v) =>
                  v != _password.text ? 'Passwords do not match.' : null,
              onFieldSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              key: const Key('savePasswordButton'),
              onPressed: _busy ? null : _submit,
              icon: const Icon(Icons.check),
              label: const Text('Save and continue'),
            ),
            TextButton(
              onPressed: () => ref.read(authProvider.notifier).logout(),
              child: const Text('Sign out'),
            ),
          ],
        ),
      ),
    );
  }
}
