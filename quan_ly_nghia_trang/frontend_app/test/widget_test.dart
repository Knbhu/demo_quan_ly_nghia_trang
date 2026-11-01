// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:sala_garden/main.dart';

void main() {
  testWidgets('Sala Garden public landing page renders', (WidgetTester tester) async {
    await tester.pumpWidget(const SalaGardenApp());
    expect(find.text('NƠI AN NGHỈ AN YÊN'), findsOneWidget);
    expect(find.text('DỊCH VỤ TẠI SALA GARDEN'), findsOneWidget);
  });
}
