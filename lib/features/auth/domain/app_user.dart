import '../../../core/database/row_reader.dart';

/// Things that can be restricted per role.
enum Permission {
  /// Settings screen (business, printer, tax, modules, data, users).
  manageSettings,
  manageUsers,
  manageExpenses,

  /// Reports module and the profit & loss / budget cards.
  viewReports,

  /// Add, edit, (de)activate products and adjust stock.
  manageProducts,

  /// Void sales and return items.
  voidSales,
}

enum UserRole {
  admin('Admin', Permission.values),
  seller('Seller', []);

  const UserRole(this.label, this.permissions);

  final String label;
  final List<Permission> permissions;

  static UserRole parse(String value) => UserRole.values.firstWhere(
    (r) => r.name == value,
    orElse: () => UserRole.seller,
  );
}

class AppUser {
  const AppUser({
    required this.id,
    required this.username,
    required this.displayName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.lastLoginAt,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  bool get isAdmin => role == UserRole.admin;

  bool can(Permission permission) => role.permissions.contains(permission);

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map.stringOf('id'),
    username: map.stringOf('username'),
    displayName: map.stringOf('display_name'),
    role: UserRole.parse(map.stringOf('role')),
    isActive: map.boolOf('is_active', true),
    createdAt: map.dateOf('created_at'),
    lastLoginAt: map.dateOrNull('last_login_at'),
  );
}
