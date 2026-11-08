import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/data/repositories/flashcard_repository.dart';

void main() {
  late AppDatabase db;
  late FlashcardRepository repo;
  late int topicId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = FlashcardRepository(db);

    final courseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Course'));
    topicId = await db
        .into(db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: 'Topic'));
  });

  tearDown(() => db.close());

  Future<Flashcard> getCard(int id) =>
      (db.select(db.flashcards)..where((f) => f.id.equals(id))).getSingle();

  test('new cards start in box 1 and are due immediately', () async {
    final id = await repo.addFlashcard(topicId: topicId, front: 'Q', back: 'A');

    final card = await getCard(id);
    expect(card.box, 1);
    expect(await repo.getDueCards(topicId), hasLength(1));
  });

  test('remembered moves up a box and is no longer due', () async {
    final id = await repo.addFlashcard(topicId: topicId, front: 'Q', back: 'A');

    await repo.recordReview(id: id, remembered: true);

    final card = await getCard(id);
    expect(card.box, 2);
    expect(card.lastReviewedAt, isNotNull);
    // Box 2 = 2 days ahead (allow a couple of minutes of slack).
    expect(
      card.dueAt.difference(DateTime.now()).inMinutes,
      closeTo(2 * 24 * 60, 2),
    );
    expect(await repo.getDueCards(topicId), isEmpty);
  });

  test('missed sends the card back to box 1', () async {
    final id = await repo.addFlashcard(topicId: topicId, front: 'Q', back: 'A');
    await repo.recordReview(id: id, remembered: true);
    await repo.recordReview(id: id, remembered: true);

    await repo.recordReview(id: id, remembered: false);

    expect((await getCard(id)).box, 1);
  });

  test('box never goes above the maximum', () async {
    final id = await repo.addFlashcard(topicId: topicId, front: 'Q', back: 'A');

    for (var i = 0; i < FlashcardRepository.maxBox + 3; i++) {
      await repo.recordReview(id: id, remembered: true);
    }

    expect((await getCard(id)).box, FlashcardRepository.maxBox);
  });

  test('deleting a topic deletes its flashcards', () async {
    await repo.addFlashcard(topicId: topicId, front: 'Q', back: 'A');

    await (db.delete(db.topics)..where((t) => t.id.equals(topicId))).go();

    expect(await db.select(db.flashcards).get(), isEmpty);
  });
}
