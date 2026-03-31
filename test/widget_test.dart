import 'package:flutter_test/flutter_test.dart';
import 'package:lotto_analyzer/main.dart';

void main() {
  testWidgets('App renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const LottoAnalyzerApp());
    expect(find.text('LOTTO ANALYZER'), findsOneWidget);
  });
}
