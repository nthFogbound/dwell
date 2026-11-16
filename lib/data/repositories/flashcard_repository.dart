import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

class FlashcardRepository {
  FlashcardRepository(this._db);

  final AppDatabase _db;

  /// Days until a card is due again, indexed by box (box 1 = index 0).
  static const _boxIntervalDays = [1, 2, 4, 7, 14];
  static int get maxBox => _boxIntervalDays.length;

  static List<String> parseTags(String? tagText) {
    final text = tagText ?? '';
    if (text.trim().isEmpty) return const [];
    final tags = text
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .toList();
    tags.sort();
    return tags;
  }

  static String normalizeTags(String? tagText) {
    final tags = parseTags(tagText);
    return tags.join(', ');
  }

  /// Live list of one topic's flashcards, oldest first.
  Stream<List<Flashcard>> watchFlashcards(int topicId) {
    return (_db.select(_db.flashcards)
          ..where((f) => f.topicId.equals(topicId))
          ..orderBy([(f) => OrderingTerm.asc(f.createdAt)]))
        .watch();
  }

  Future<int> addFlashcard({
    required int topicId,
    required String front,
    required String back,
    String? tags,
  }) {
    return _db
        .into(_db.flashcards)
        .insert(
          FlashcardsCompanion.insert(
            topicId: topicId,
            front: front.trim(),
            back: back.trim(),
            tags: Value(normalizeTags(tags)),
          ),
        );
  }

  Future<int> updateFlashcard({
    required int id,
    required String front,
    required String back,
    String? tags,
  }) {
    return (_db.update(_db.flashcards)..where((f) => f.id.equals(id))).write(
      FlashcardsCompanion(
        front: Value(front.trim()),
        back: Value(back.trim()),
        tags: Value(normalizeTags(tags)),
      ),
    );
  }

  Future<int> deleteFlashcard(int id) {
    return (_db.delete(_db.flashcards)..where((f) => f.id.equals(id))).go();
  }

  /// One-time snapshot of cards due now, most overdue first.
  /// A snapshot (not a live stream) keeps the review queue stable mid-session.
  Future<List<Flashcard>> getDueCards(int topicId) {
    return (_db.select(_db.flashcards)
          ..where(
            (f) =>
                f.topicId.equals(topicId) &
                f.dueAt.isSmallerOrEqualValue(DateTime.now()),
          )
          ..orderBy([(f) => OrderingTerm.asc(f.dueAt)]))
        .get();
  }

  /// Snapshot of every card in one topic, oldest first.
  Future<List<Flashcard>> getAllCards(int topicId) {
    return (_db.select(_db.flashcards)
          ..where((f) => f.topicId.equals(topicId))
          ..orderBy([(f) => OrderingTerm.asc(f.createdAt)]))
        .get();
  }

  /// Applies a Leitner result: remembered moves up a box, missed returns to box 1.
  Future<void> recordReview({required int id, required bool remembered}) {
    return _db.transaction(() async {
      final card = await (_db.select(
        _db.flashcards,
      )..where((f) => f.id.equals(id))).getSingle();

      final newBox = remembered ? min(card.box + 1, maxBox) : 1;
      final now = DateTime.now();

      await (_db.update(_db.flashcards)..where((f) => f.id.equals(id))).write(
        FlashcardsCompanion(
          box: Value(newBox),
          dueAt: Value(now.add(Duration(days: _boxIntervalDays[newBox - 1]))),
          lastReviewedAt: Value(now),
        ),
      );
    });
  }
}
