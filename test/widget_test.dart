import 'package:flutter_test/flutter_test.dart';

import 'package:stock_ease/main.dart';
import 'package:stock_ease/src/models/models.dart';

void main() {
  testWidgets('shows setup guidance when Supabase config is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissingConfigurationApp());

    expect(find.text('StockEase needs Supabase settings'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });

  test('product input lets Supabase generate missing SKU and barcode', () {
    const input = ProductInput(
      name: 'Rice',
      categoryName: 'Grocery',
      sku: null,
      barcode: null,
      costPrice: 40,
      sellingPrice: 50,
      stockQuantity: 10,
      lowStockThreshold: 3,
      isActive: true,
    );

    final json = input.toJson(
      businessId: 'business-id',
      categoryId: 'category-id',
    );

    expect(json['sku'], isNull);
    expect(json['barcode'], isNull);
  });
}
