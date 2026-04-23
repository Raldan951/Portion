import 'package:flutter_test/flutter_test.dart';
import 'package:portion/app.dart';

void main() {
  testWidgets('HomeScreen renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const PortionApp());
    expect(find.text('Portion'), findsWidgets);
  });
}
