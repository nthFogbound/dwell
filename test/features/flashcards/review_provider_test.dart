import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/data/repositories/flashcard_repository.dart';
import 'package:dwell/features/flashcards/review_provider.dart';

void main() {
  test('review all cards includes cards scheduled for later', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = FlashcardRepository(db);
    final courseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Course'));
    final topicId = await db
        .into(db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
    final cardId = await repository.addFlashcard(
      topicId: topicId,
      front: 'Question',
      back: 'Answer',
    );
    await repository.recordReview(id: cardId, remembered: true);

    final loaded = Completer<void>();
    final provider = ReviewProvider(repository, topicId)
      ..addListener(() {
        if (!loaded.isCompleted) loaded.complete();
      });
    addTearDown(provider.dispose);
    await loaded.future;
    expect(provider.hasNothingDue, isTrue);

    await provider.reviewAllCards();

    expect(provider.hasNothingDue, isFalse);
    expect(provider.currentCard?.front, 'Question');
  });

  test('restart replays the queue and clears this round summary', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = FlashcardRepository(db);
    final courseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Course'));
    final topicId = await db
        .into(db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
    await repository.addFlashcard(
      topicId: topicId,
      front: 'Question',
      back: 'Answer',
    );

    final loaded = Completer<void>();
    final provider = ReviewProvider(repository, topicId)
      ..addListener(() {
        if (!loaded.isCompleted) loaded.complete();
      });
    addTearDown(provider.dispose);
    await loaded.future;

    provider.reveal();
    await provider.answer(remembered: true);
    expect(provider.isComplete, isTrue);
    expect(provider.rememberedCount, 1);

    provider.restart();

    expect(provider.isComplete, isFalse);
    expect(provider.currentCard?.front, 'Question');
    expect(provider.isRevealed, isFalse);
    expect(provider.rememberedCount, 0);
    expect(provider.missedCount, 0);
  });
}
