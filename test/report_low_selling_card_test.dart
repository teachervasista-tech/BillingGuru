import 'package:billing_guru/features/reports/data/models/report_models.dart';
import 'package:billing_guru/features/reports/presentation/widgets/low_stock_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('slow-moving card labels sales within the selected period', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LowStockCard(
            periodLabel: 'in the last 7 days',
            products: [
              const LowStockReport(
                productId: 'p1',
                shortCode: 'COF001',
                productName: 'Coffee',
                soldQuantity: 3,
              ),
              const LowStockReport(
                productId: 'p2',
                shortCode: 'TEA001',
                productName: 'Tea',
                soldQuantity: 0,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Slow-moving products'), findsOneWidget);
    expect(find.text('3 sold'), findsOneWidget);
    expect(find.text('Sold 3 in the last 7 days'), findsOneWidget);
    expect(find.text('Not sold in the last 7 days'), findsOneWidget);
  });
}
