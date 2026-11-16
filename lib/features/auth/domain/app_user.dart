import '../../../core/database/row_reader.dart';

/// Things that can be restricted per role.
enum Permission {
  /// The Settings screen itself (which tabs show depends on the others).
  openSettings,

  /// Settings → Business, Printer, Payment options, Modules; on the Data tab,
  /// restore and choosing the backup folder.
  configureSystem,

  /// Settings → Data: see backup status and run a backup now.
  backupData,

  /// Settings → Tax (default tax rate).
  manageTax,

  /// Settings → Users: create and manage Admin / Seller accounts.
  manageUsers,

  /// Settings → Product categories and Expense categories.
  manageCategories,

  /// Day-to-day screens: Dashboard, PoS, Products, Customers, Sales,
  /// Inventory.
  operate,
  manageExpenses,

  /// Reports module and the profit & loss / budget cards.
  viewReports,

  /// Add, edit, (de)activate products and adjust stock.
  manageProducts,

  /// Void sales and return items.
  voidSales,
}

enum UserRole {
  /// Built-in account that sets the system up; no shop operations.
  installer('Installer', [
    Permission.openSettings,
    Permission.configureSystem,
    Permission.backupData,
    Permission.manageTax,
    Permission.manageUsers,
  ]),
  admin('Admin', [
    Permission.openSettings,
    Permission.backupData,
    Permission.manageTax,
    Permission.manageUsers,
    Permission.manageCategories,
    Permission.operate,
    Permission.manageExpenses,
    Permission.viewReports,
    Permission.manageProducts,
    Permission.voidSales,
  ]),
  seller('Seller', [Permission.operate]);

  const UserRole(this.label, this.permissions);

  final String label;
  final List<Permission> permissions;

  /// Roles that can be given to accounts created in Settings → Users.
  static const assignable = [UserRole.admin, UserRole.seller];

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
    this.mustChangePassword = false,
  });

  final String id;
  final String username;
  final String displayName;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  /// Set for the built-in installer until its default password is changed.
  final bool mustChangePassword;

  bool get isAdmin => role == UserRole.admin;
  bool get isInstaller => role == UserRole.installer;

  bool can(Permission permission) => role.permissions.contains(permission);

  AppUser copyWith({bool? mustChangePassword}) => AppUser(
    id: id,
    username: username,
    displayName: displayName,
    role: role,
    createdAt: createdAt,
    isActive: isActive,
    lastLoginAt: lastLoginAt,
    mustChangePassword: mustChangePassword ?? this.mustChangePassword,
  );

  factory AppUser.fromMap(Map<String, Object?> map) => AppUser(
    id: map.stringOf('id'),
    username: map.stringOf('username'),
    displayName: map.stringOf('display_name'),
    role: UserRole.parse(map.stringOf('role')),
    isActive: map.boolOf('is_active', true),
    createdAt: map.dateOf('created_at'),
    lastLoginAt: map.dateOrNull('last_login_at'),
    mustChangePassword: map.boolOf('must_change_password'),
  );
}
