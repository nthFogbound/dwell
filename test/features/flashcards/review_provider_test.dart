import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/data/repositories/flashcard_repository.dart';
import 'package:dwell/core/settings/settings_provider.dart';
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

  test(
    'missed cards repeat after the configured gap until remembered',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final repository = FlashcardRepository(db);
      final courseId = await db
          .into(db.courses)
          .insert(CoursesCompanion.insert(name: 'Course'));
      final topicId = await db
          .into(db.topics)
          .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
      for (final front in ['First', 'Second', 'Third']) {
        await repository.addFlashcard(
          topicId: topicId,
          front: front,
          back: 'Answer',
        );
      }

      final provider = ReviewProvider(
        repository,
        topicId,
        repeatGap: MissedCardRepeatGap.afterTwoCards,
      );
      addTearDown(provider.dispose);
      await _waitUntilLoaded(provider);

      expect(provider.currentCard?.front, 'First');
      provider.reveal();
      await provider.answer(remembered: false);
      expect(provider.currentCard?.front, 'Second');

      provider.reveal();
      await provider.answer(remembered: true);
      expect(provider.currentCard?.front, 'Third');

      provider.reveal();
      await provider.answer(remembered: true);
      expect(provider.currentCard?.front, 'First');
      expect(provider.currentCardIsRepeat, isTrue);

      provider.reveal();
      await provider.answer(remembered: true);
      expect(provider.isComplete, isTrue);
      expect(provider.reviewedCount, 3);
      expect(provider.attempts, 4);
      expect(provider.missedCardsCount, 1);
      expect(provider.accuracy, 0.75);
    },
  );

  test(
    'undo restores the prior schedule and returns the card to answer',
    () async {
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
      final before = await (db.select(
        db.flashcards,
      )..where((card) => card.id.equals(cardId))).getSingle();

      final provider = ReviewProvider(repository, topicId);
      addTearDown(provider.dispose);
      await _waitUntilLoaded(provider);
      provider.reveal();
      await provider.answer(remembered: false);

      final afterAnswer = await (db.select(
        db.flashcards,
      )..where((card) => card.id.equals(cardId))).getSingle();
      expect(afterAnswer.lastReviewedAt, isNotNull);
      expect(provider.canUndo, isTrue);

      expect(await provider.undoLastResponse(), isTrue);
      final restored = await (db.select(
        db.flashcards,
      )..where((card) => card.id.equals(cardId))).getSingle();
      expect(restored.box, before.box);
      expect(restored.dueAt, before.dueAt);
      expect(restored.lastReviewedAt, before.lastReviewedAt);
      expect(provider.currentCard?.id, cardId);
      expect(provider.isRevealed, isFalse);
      expect(provider.reviewedCount, 0);
      expect(provider.attempts, 0);
      expect(provider.canUndo, isFalse);
    },
  );

  test('undo history retains the most recent five responses', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final repository = FlashcardRepository(db);
    final courseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Course'));
    final topicId = await db
        .into(db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
    for (var i = 0; i < 6; i++) {
      await repository.addFlashcard(
        topicId: topicId,
        front: 'Question $i',
        back: 'Answer',
      );
    }

    final provider = ReviewProvider(repository, topicId);
    addTearDown(provider.dispose);
    await _waitUntilLoaded(provider);
    for (var i = 0; i < 6; i++) {
      provider.reveal();
      await provider.answer(remembered: true);
    }
    for (var i = 0; i < 5; i++) {
      expect(await provider.undoLastResponse(), isTrue);
    }
    expect(await provider.undoLastResponse(), isFalse);
    expect(provider.attempts, 1);
    expect(provider.reviewedCount, 1);
    expect(provider.currentCard?.front, 'Question 1');
  });
}

Future<void> _waitUntilLoaded(ReviewProvider provider) async {
  if (!provider.isLoading) return;
  final loaded = Completer<void>();
  void listener() {
    if (!provider.isLoading && !loaded.isCompleted) loaded.complete();
  }

  provider.addListener(listener);
  if (!provider.isLoading) loaded.complete();
  await loaded.future;
  provider.removeListener(listener);
}
