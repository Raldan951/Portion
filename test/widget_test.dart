import 'package:flutter_test/flutter_test.dart';
import 'package:biblejournal_v2/app.dart';

void main() {
  testWidgets('HomeScreen renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const BibleJournalApp());
    expect(find.text('BibleJournal'), findsWidgets);
  });
}
