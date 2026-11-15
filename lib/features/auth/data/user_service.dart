import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../domain/app_user.dart';
import 'password_hasher.dart';

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class UserService {
  UserService({required this.database, this.hasher = const PasswordHasher()});

  final AppDatabase database;
  final PasswordHasher hasher;
  static const _uuid = Uuid();
  static const minPasswordLength = 6;

  static String? validateUsername(String? value) {
    final text = (value ?? '').trim();
    if (text.length < 3) return 'At least 3 characters.';
    if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(text)) {
      return 'Letters, numbers, dot, dash or underscore only.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    return (value ?? '').length < minPasswordLength
        ? 'At least $minPasswordLength characters.'
        : null;
  }

  Future<bool> hasUsers() async {
    final db = await database.database;
    final row = (await db.rawQuery('SELECT COUNT(*) AS n FROM users')).first;
    return row.intOf('n') > 0;
  }

  Future<List<AppUser>> getUsers() async {
    final db = await database.database;
    final rows = await db.query(
      'users',
      orderBy: "role = 'admin' DESC, display_name COLLATE NOCASE",
    );
    return rows.map(AppUser.fromMap).toList();
  }

  Future<AppUser> createUser({
    required String username,
    required String displayName,
    required String password,
    required UserRole role,
  }) async {
    final usernameError = validateUsername(username);
    if (usernameError != null) throw AuthException('Username: $usernameError');
    final passwordError = validatePassword(password);
    if (passwordError != null) throw AuthException('Password: $passwordError');

    final db = await database.database;
    final user = AppUser(
      id: _uuid.v4(),
      username: username.trim(),
      displayName: displayName.trim().isEmpty
          ? username.trim()
          : displayName.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    try {
      await db.insert('users', {
        'id': user.id,
        'username': user.username,
        'display_name': user.displayName,
        'role': role.name,
        'password_hash': hasher.hash(password),
        'is_active': 1,
        'created_at': user.createdAt.toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.abort);
    } on DatabaseException catch (error) {
      if (error.isUniqueConstraintError()) {
        throw AuthException('The username "${user.username}" is taken.');
      }
      rethrow;
    }
    return user;
  }

  /// Returns the user when the credentials are valid and the account is
  /// active; otherwise throws [AuthException] with a generic message.
  Future<AppUser> authenticate(String username, String password) async {
    final db = await database.database;
    final rows = await db.query(
      'users',
      where: 'username = ?',
      whereArgs: [username.trim()],
      limit: 1,
    );
    const invalid = AuthException('Incorrect username or password.');
    if (rows.isEmpty) {
      // Spend comparable time so usernames can't be probed by timing.
      hasher.verify(password, hasher.hash('timing-equaliser'));
      throw invalid;
    }
    final row = rows.first;
    if (!hasher.verify(password, row.stringOf('password_hash'))) throw invalid;
    final user = AppUser.fromMap(row);
    if (!user.isActive) {
      throw const AuthException('This account is disabled. Ask an admin.');
    }
    await db.update(
      'users',
      {'last_login_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [user.id],
    );
    return user;
  }

  Future<void> setPassword(String userId, String password) async {
    final error = validatePassword(password);
    if (error != null) throw AuthException('Password: $error');
    final db = await database.database;
    await db.update(
      'users',
      {'password_hash': hasher.hash(password)},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  /// Changes a user's own password after checking the current one.
  Future<void> changeOwnPassword(
    AppUser user,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      await authenticate(user.username, currentPassword);
    } on AuthException {
      throw const AuthException('Current password is incorrect.');
    }
    await setPassword(user.id, newPassword);
  }

  Future<void> updateUser(
    String userId, {
    String? displayName,
    UserRole? role,
    bool? isActive,
  }) async {
    final db = await database.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );
      if (rows.isEmpty) throw const AuthException('User not found.');
      final current = AppUser.fromMap(rows.first);
      final losesAdmin =
          current.isAdmin &&
          current.isActive &&
          ((role != null && role != UserRole.admin) || isActive == false);
      if (losesAdmin) {
        final admins = (await txn.rawQuery(
          "SELECT COUNT(*) AS n FROM users WHERE role = 'admin' AND is_active = 1",
        )).first.intOf('n');
        if (admins <= 1) {
          throw const AuthException(
            'There must always be at least one active admin.',
          );
        }
      }
      await txn.update(
        'users',
        {
          if (displayName != null && displayName.trim().isNotEmpty)
            'display_name': displayName.trim(),
          if (role != null) 'role': role.name,
          if (isActive != null) 'is_active': isActive ? 1 : 0,
        },
        where: 'id = ?',
        whereArgs: [userId],
      );
    });
  }
}
