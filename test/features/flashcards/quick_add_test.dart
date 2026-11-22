import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:dwell/core/settings/settings_provider.dart';
import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/data/repositories/flashcard_repository.dart';
import 'package:dwell/data/repositories/topic_repository.dart';
import 'package:dwell/features/flashcards/widgets/quick_add_dialog.dart';

void main() {
  testWidgets('quick add saves cards and keeps the selected topic', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final courseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Course'));
    final topicId = await db
        .into(db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
    final settings = _MemorySettingsProvider();
    addTearDown(settings.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<TopicRepository>(create: (_) => TopicRepository(db)),
          Provider<FlashcardRepository>(create: (_) => FlashcardRepository(db)),
          ChangeNotifierProvider<SettingsProvider>.value(value: settings),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showQuickAddDialog(context),
                child: const Text('Open quick add'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open quick add'));
    await tester.pumpAndSettle();
    expect(find.text('Quick add'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'First question');
    await tester.enterText(find.byType(TextFormField).at(1), 'First answer');
    await tester.tap(find.text('Save & Add Another'));
    await tester.pumpAndSettle();

    expect(await db.select(db.flashcards).get(), hasLength(1));
    expect(settings.lastTopicId, topicId);
    expect(find.text('Quick add'), findsOneWidget);
    expect(find.byType(TextFormField).at(0), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).at(0), 'Second question');
    await tester.enterText(find.byType(TextFormField).at(1), 'Second answer');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final cards = await db.select(db.flashcards).get();
    expect(cards, hasLength(2));
    expect(
      cards.map((card) => card.front),
      containsAll(['First question', 'Second question']),
    );
    expect(find.text('Quick add'), findsNothing);
  });
}

class _MemorySettingsProvider extends SettingsProvider {
  int? _lastTopicId;

  @override
  int? get lastTopicId => _lastTopicId;

  @override
  Future<void> setLastTopicId(int? value) async {
    _lastTopicId = value;
  }
}
