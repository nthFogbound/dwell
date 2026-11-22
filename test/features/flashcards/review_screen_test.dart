import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import 'package:dwell/core/settings/settings_provider.dart';
import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/data/repositories/flashcard_repository.dart';
import 'package:dwell/features/flashcards/review_provider.dart';
import 'package:dwell/features/flashcards/review_screen.dart';

void main() {
  testWidgets('enter reveals the answer and number keys rate the card', (
    tester,
  ) async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = FlashcardRepository(db);

    final courseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Course'));
    final topicId = await db
        .into(db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
    final topic = await (db.select(
      db.topics,
    )..where((t) => t.id.equals(topicId))).getSingle();
    await repository.addFlashcard(
      topicId: topicId,
      front: 'Question',
      back: 'Answer',
    );

    final provider = ReviewProvider(repository, topicId);
    addTearDown(provider.dispose);

    final loaded = Completer<void>();
    void listener() {
      if (!provider.isLoading && !loaded.isCompleted) {
        loaded.complete();
      }
    }

    provider.addListener(listener);
    if (!provider.isLoading) {
      loaded.complete();
    }
    await loaded.future;
    provider.removeListener(listener);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ReviewProvider>.value(value: provider),
          ChangeNotifierProvider<SettingsProvider>(
            create: (_) => SettingsProvider(),
          ),
        ],
        child: MaterialApp(home: ReviewScreen(topic: topic)),
      ),
    );

    expect(find.text('Question'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('Question')).textAlign,
      TextAlign.center,
    );
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(find.text('Answer'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.digit2);
    await tester.pump();
    expect(provider.isComplete, isTrue);

    await tester.tap(find.text('Undo last response'));
    await tester.pump();
    expect(provider.isComplete, isFalse);
    expect(find.text('Response undone'), findsOneWidget);
  });
}
