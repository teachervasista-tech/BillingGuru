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
  const AuthState({this.needsSetup = false, this.user});

  /// No accounts exist yet: the first admin must be created.
  final bool needsSetup;
  final AppUser? user;
}

final authProvider = AsyncNotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<AuthState> {
  UserService get _users => ref.read(userServiceProvider);

  @override
  Future<AuthState> build() async {
    return AuthState(needsSetup: !await _users.hasUsers());
  }

  Future<void> login(String username, String password) async {
    final user = await _users.authenticate(username, password);
    state = AsyncData(AuthState(user: user));
  }

  Future<void> createFirstAdmin({
    required String username,
    required String displayName,
    required String password,
  }) async {
    if (await _users.hasUsers()) {
      throw const AuthException('An admin account already exists.');
    }
    final user = await _users.createUser(
      username: username,
      displayName: displayName,
      password: password,
      role: UserRole.admin,
    );
    state = AsyncData(AuthState(user: user));
  }

  void logout() {
    state = const AsyncData(AuthState());
  }

  /// Re-reads whether accounts exist (e.g. after restoring a backup) and
  /// signs the current user out.
  Future<void> reset() async {
    state = AsyncData(AuthState(needsSetup: !await _users.hasUsers()));
  }

  /// Keeps the signed-in user's name/role current after an admin edit.
  void refreshCurrent(AppUser updated) {
    if (state.value?.user?.id == updated.id) {
      state = AsyncData(AuthState(user: updated));
    }
  }
}

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authProvider).value?.user;
});

/// Whether the signed-in user has [Permission]. False when signed out.
final canProvider = Provider.family<bool, Permission>((ref, permission) {
  return ref.watch(currentUserProvider)?.can(permission) ?? false;
});
