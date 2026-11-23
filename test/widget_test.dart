import 'package:flutter_test/flutter_test.dart';
import 'package:beproud/main.dart';

void main() {
  testWidgets('Carrega app BeProud', (WidgetTester tester) async {
    await tester.pumpWidget(const BeProudApp());
  });
}