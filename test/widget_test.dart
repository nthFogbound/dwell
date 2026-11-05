import 'package:flutter_test/flutter_test.dart';
import 'package:dwell/app.dart';

void main() {
  testWidgets('app shell shows navigation destinations', (tester) async {
    await tester.pumpWidget(const DwellApp());
    expect(find.text('Courses'), findsWidgets);
    expect(find.text('Flashcards'), findsOneWidget);
  });
}