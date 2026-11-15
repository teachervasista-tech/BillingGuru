import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_provider.dart';
import '../data/password_hasher.dart';
import '../data/user_service.dart';
import '../domain/app_user.dart';

export '../domain/app_user.dart';

final passwordHasherProvider = Provider<PasswordHasher>(
  (ref) => const PasswordHasher(),
);

final userServiceProvider = Provider<UserService>((ref) {
  return UserService(
    database: ref.watch(appDatabaseProvider),
    hasher: ref.watch(passwordHasherProvider),
  );
});

class AuthState {
  const AuthState({this.user});

  final AppUser? user;
}

/// Who is signed in. Accounts always exist: the installer account is created
/// with the database (see migrations), so there is no first-run setup.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AuthState> {
  UserService get _users => ref.read(userServiceProvider);

  @override
  AuthState build() => const AuthState();

  Future<void> login(String username, String password) async {
    final user = await _users.authenticate(username, password);
    state = AuthState(user: user);
  }

  /// Sets a new password for the signed-in user who was required to change
  /// it (installer default password), then lets them in.
  Future<void> completeRequiredPasswordChange(String newPassword) async {
    final user = state.user;
    if (user == null) return;
    await _users.setPassword(user.id, newPassword);
    state = AuthState(user: user.copyWith(mustChangePassword: false));
  }

  void logout() {
    state = const AuthState();
  }

  /// Signs out, e.g. after restoring a backup (accounts may have changed).
  Future<void> reset() async => logout();
}

/// Shows the first-use hint on the login screen.
final isFirstUseProvider = FutureProvider<bool>((ref) {
  ref.watch(authProvider);
  return ref.watch(userServiceProvider).isFirstUse();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).user;
});

/// Whether the signed-in user has [Permission]. False when signed out.
final canProvider = Provider.family<bool, Permission>((ref, permission) {
  return ref.watch(currentUserProvider)?.can(permission) ?? false;
});
