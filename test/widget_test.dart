import 'package:flutter_test/flutter_test.dart';
import 'package:eu_mart_web/main.dart';

void main() {
  testWidgets('EU MART app starts', (WidgetTester tester) async {
    await tester.pumpWidget(const EuMartWebApp());
  });
}
