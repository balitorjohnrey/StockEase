import 'package:flutter_test/flutter_test.dart';

import 'package:stock_ease/main.dart';

void main() {
  testWidgets('shows setup guidance when Supabase config is missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MissingConfigurationApp());

    expect(find.text('StockEase needs Supabase settings'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
  });
}
