import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dwell/app.dart';
import 'package:dwell/core/navigation/navigation_provider.dart';

void main() {
  testWidgets('selecting a destination changes the section', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => NavigationProvider(),
        child: const DwellApp(),
      ),
    );

    await tester.tap(find.text('Quiz'));
    await tester.pump();

    final context = tester.element(find.byType(DwellApp));
    expect(context.read<NavigationProvider>().current, AppSection.quiz);
  });
}
