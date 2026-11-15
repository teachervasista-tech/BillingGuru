import 'package:billing_guru/core/currency/currency.dart';
import 'package:billing_guru/core/database/app_database.dart';
import 'package:billing_guru/core/printing/receipt_printer_service.dart';
import 'package:billing_guru/core/printing/receipt_template.dart';
import 'package:billing_guru/features/checkout/data/repositories/checkout_repository.dart';
import 'package:billing_guru/features/checkout/domain/payment.dart';
import 'package:billing_guru/features/checkout/domain/sale.dart';
import 'package:billing_guru/features/checkout/domain/sale_item.dart';
import 'package:billing_guru/features/customers/data/customer_local_service.dart';
import 'package:billing_guru/features/customers/domain/customer.dart';
import 'package:billing_guru/features/reports/data/services/report_local_service.dart';
import 'package:billing_guru/features/sales/data/models/sale_summary.dart';
import 'package:billing_guru/features/sales/data/services/sales_local_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_container.dart';

void main() {
  late AppDatabase database;
  late SalesLocalService sales;
  late ReportLocalService reports;
  final day = DateTime(2026, 11, 10, 12);
  final from = DateTime(2026, 11);
  final to = DateTime(2026, 12);

  setUp(() async {
    database = createTestDatabase();
    sales = SalesLocalService(database: database);
    reports = ReportLocalService(database: database);
    final db = await database.database;
    await db.insert('products', {
      'id': 'tea',
      'short_code': 'TEA',
      'name': 'Tea',
      'price_cents': 200,
      'tax_rate': 10,
      'stock_quantity': 20,
      'cost_price_cents': 80,
    });
  });
  tearDown(() => database.close());

  /// 3 x Tea (200) + 2 x TestCoffee (299); 10% tax on 1198 -> 119.
  Future<Sale> recordSale({String? customerId}) async {
    final sale = Sale(
      id: 's1',
      invoiceNumber: 'INV-1',
      items: const [
        SaleItem(
          id: 'i-tea',
          saleId: 's1',
          productId: 'tea',
          quantity: 3,
          unitPriceCents: 200,
          totalCents: 600,
          unitCostCents: 80,
        ),
        SaleItem(
          id: 'i-coffee',
          saleId: 's1',
          productId: 'Test-001',
          quantity: 2,
          unitPriceCents: 299,
          totalCents: 598,
        ),
      ],
      subtotalCents: 1198,
      discountCents: 0,
      taxCents: 119,
      totalCents: 1317,
      paymentMethod: PaymentMethod.cash,
      createdAt: day,
      syncStatus: 'pending',
      customerId: customerId,
    );
    await CheckoutRepository(database: database).saveSale(sale);
    return sale;
  }

  Future<int> stockOf(String id) async {
    final db = await database.database;
    return (await db.query(
          'products',
          where: 'id = ?',
          whereArgs: [id],
        )).single['stock_quantity']
        as int;
  }

  test(
    'voiding a sale restocks everything and removes it from reports',
    () async {
      await recordSale();
      expect(await stockOf('tea'), 17);

      await sales.voidSale('s1', reason: 'Wrong order');

      expect(await stockOf('tea'), 20);
      expect(await stockOf('Test-001'), 50);
      final sale = (await sales.getSaleById('s1'))!;
      expect(sale.status, SaleStatus.voided);
      expect(sale.netTotalCents, 0);

      final summary = await reports.getSalesSummary(from: from, to: to);
      expect(summary.totalSalesCents, 0);
      expect(summary.totalTransactions, 0);
      final pl = await reports.getProfitLoss(from: from, to: to);
      expect(pl.salesCents, 0);
      expect(pl.cogsCents, 0);

      expect(
        () => sales.voidSale('s1'),
        throwsA(isA<StateError>()),
        reason: 'a voided sale cannot be voided again',
      );
    },
  );

  test('partial return refunds price plus proportional tax', () async {
    await recordSale();

    await sales.returnItems('s1', {'i-tea': 2});

    expect(await stockOf('tea'), 19);
    final sale = (await sales.getSaleById('s1'))!;
    expect(sale.status, SaleStatus.partiallyRefunded);
    // 400 + round(400 * 119 / 1198) = 400 + 40
    expect(sale.refundedCents, 440);

    final items = await sales.getSaleItems('s1');
    expect(items.firstWhere((i) => i.id == 'i-tea').returnableQuantity, 1);

    final pl = await reports.getProfitLoss(from: from, to: to);
    expect(pl.salesCents, 1317 - 440);
    expect(pl.taxCollectedCents, 119 - 40);
    expect(pl.cogsCents, 80); // 1 tea left at cost 80; coffee has no cost
    final top = await reports.getTopProducts(from: from, to: to);
    expect(top.firstWhere((t) => t.productId == 'tea').quantity, 1);

    expect(
      () => sales.returnItems('s1', {'i-tea': 2}),
      throwsA(isA<StateError>()),
      reason: 'only 1 tea is left to return',
    );
  });

  test('returning everything settles exactly to the sale total', () async {
    await recordSale();
    await sales.returnItems('s1', {'i-tea': 1});
    await sales.returnItems('s1', {'i-tea': 2, 'i-coffee': 2});

    final sale = (await sales.getSaleById('s1'))!;
    expect(sale.status, SaleStatus.refunded);
    expect(sale.refundedCents, 1317);
    final pl = await reports.getProfitLoss(from: from, to: to);
    expect(pl.salesCents, 0);
    expect(pl.taxCollectedCents, 0);
  });

  group('customers', () {
    test('sale is linked, searchable and counted in lifetime value', () async {
      final customers = CustomerLocalService(database: database);
      await customers.saveCustomer(
        Customer(
          id: 'c1',
          name: 'Asha Rao',
          phone: '98450',
          createdAt: DateTime(2026),
        ),
      );
      await recordSale(customerId: 'c1');

      expect((await customers.getCustomers(search: '9845')).single.id, 'c1');
      final listed = (await sales.getSales(search: 'asha')).single;
      expect(listed.customerName, 'Asha Rao');
      expect((await sales.getSales(customerId: 'c1')).length, 1);

      var stats = await customers.getStats('c1');
      expect(stats.purchaseCount, 1);
      expect(stats.lifetimeValueCents, 1317);

      await sales.returnItems('s1', {'i-tea': 2});
      stats = await customers.getStats('c1');
      expect(stats.lifetimeValueCents, 1317 - 440);

      await customers.deleteCustomer('c1');
      expect(await customers.getCustomers(), isEmpty);
      expect((await sales.getSaleById('s1'))!.customerId, isNull);
    });

    test('receipt prints the customer name', () {
      final text = ReceiptFormatter.format(
        Sale(
          id: 's',
          invoiceNumber: 'INV-9',
          items: const [],
          subtotalCents: 0,
          discountCents: 0,
          taxCents: 0,
          totalCents: 0,
          paymentMethod: PaymentMethod.cash,
          createdAt: day,
          syncStatus: 'pending',
          customerName: 'Asha Rao',
        ),
        AppCurrency.inr,
        template: ReceiptTemplate.classic,
        businessDetails: 'Shop',
      );
      expect(text, contains('Customer: Asha Rao'));
    });
  });
}
