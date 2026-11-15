import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/row_reader.dart';
import '../domain/customer.dart';

class CustomerLocalService {
  CustomerLocalService({required this.database});

  final AppDatabase database;
  static const _uuid = Uuid();

  String newId() => _uuid.v4();

  Future<List<Customer>> getCustomers({String search = ''}) async {
    final db = await database.database;
    final text = search.trim();
    final rows = await db.query(
      'customers',
      where: text.isEmpty
          ? null
          : '(name LIKE ? OR phone LIKE ? OR email LIKE ?)',
      whereArgs: text.isEmpty ? null : ['%$text%', '%$text%', '%$text%'],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<void> saveCustomer(Customer customer) async {
    final db = await database.database;
    await db.insert(
      'customers',
      customer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Deletes the customer; their past sales are kept as walk-in sales.
  Future<void> deleteCustomer(String id) async {
    final db = await database.database;
    await db.transaction((txn) async {
      await txn.update(
        'sales',
        {'customer_id': null},
        where: 'customer_id = ?',
        whereArgs: [id],
      );
      await txn.delete('customers', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<CustomerStats> getStats(String customerId) async {
    final db = await database.database;
    final row = (await db.rawQuery(
      '''
      SELECT
        COUNT(*) AS purchase_count,
        COALESCE(SUM(total_cents), 0) AS lifetime_cents,
        MAX(created_at) AS last_purchase
      FROM effective_sales
      WHERE customer_id = ?
      ''',
      [customerId],
    )).first;
    return CustomerStats(
      purchaseCount: row.intOf('purchase_count'),
      lifetimeValueCents: row.intOf('lifetime_cents'),
      lastPurchaseAt: row.dateOrNull('last_purchase'),
    );
  }
}
