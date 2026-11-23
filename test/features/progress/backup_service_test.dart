import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/features/progress/backup_service.dart';

void main() {
  late AppDatabase db;
  late Directory backupDirectory;
  late int targetCourseId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    backupDirectory = await Directory.systemTemp.createTemp('dwell_backup_');
    targetCourseId = await db
        .into(db.courses)
        .insert(
          CoursesCompanion.insert(
            name: 'Test course',
            description: const Value('Local description'),
          ),
        );
  });

  tearDown(() async {
    await db.close();
    await backupDirectory.delete(recursive: true);
  });

  test('exports the backup to the selected directory', () async {
    final path = await BackupService(db).exportData(backupDirectory.path);
    final file = File(path);

    expect(await file.exists(), isTrue);
    expect(file.parent.path, backupDirectory.path);

    final payload =
        jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(payload['courses'], hasLength(1));
    expect((payload['courses'] as List).single['name'], 'Test course');
  });

  test('merges backup data and skips duplicates on repeated imports', () async {
    final localOnlyCourseId = await db
        .into(db.courses)
        .insert(CoursesCompanion.insert(name: 'Keep course'));
    final targetTopicId = await db
        .into(db.topics)
        .insert(
          TopicsCompanion.insert(courseId: targetCourseId, name: 'BASICS'),
        );
    await db
        .into(db.flashcards)
        .insert(
          FlashcardsCompanion.insert(
            topicId: targetTopicId,
            front: 'Shared question',
            back: 'Shared answer',
            tags: const Value('shared'),
            box: const Value(4),
          ),
        );
    await db
        .into(db.flashcards)
        .insert(
          FlashcardsCompanion.insert(
            topicId: targetTopicId,
            front: 'Local question',
            back: 'Local answer',
          ),
        );
    await db
        .into(db.topics)
        .insert(
          TopicsCompanion.insert(courseId: localOnlyCourseId, name: 'Local'),
        );

    final createdAt = DateTime.utc(2025, 1, 1).toIso8601String();
    final backupFile = File(
      '${backupDirectory.path}${Platform.pathSeparator}import.json',
    );
    await backupFile.writeAsString(
      jsonEncode({
        'version': 1,
        'exportedAt': createdAt,
        'courses': [
          {
            'id': 1,
            'name': 'TEST COURSE',
            'description': 'Backup description',
            'createdAt': createdAt,
          },
        ],
        'topics': [
          {'id': 1, 'courseId': 1, 'name': 'basics', 'createdAt': createdAt},
        ],
        'flashcards': [
          {
            'id': 1,
            'topicId': 1,
            'front': 'Shared question',
            'back': 'Shared answer',
            'tags': 'shared',
            'box': 1,
            'dueAt': createdAt,
            'lastReviewedAt': null,
            'createdAt': createdAt,
          },
          {
            'id': 2,
            'topicId': 1,
            'front': 'Imported question',
            'back': 'Imported answer',
            'tags': '',
            'box': 1,
            'dueAt': createdAt,
            'lastReviewedAt': null,
            'createdAt': createdAt,
          },
        ],
        'quizAttempts': [
          {
            'id': 1,
            'courseId': 1,
            'topicId': 1,
            'totalQuestions': 2,
            'correctAnswers': 1,
            'takenAt': DateTime.utc(2025, 1, 2).toIso8601String(),
          },
        ],
      }),
    );
    final service = BackupService(db);

    await service.importData(backupFile.path);
    await service.importData(backupFile.path);

    final courses = await db.select(db.courses).get();
    final topics = await db.select(db.topics).get();
    final cards = await db.select(db.flashcards).get();
    final attempts = await db.select(db.quizAttempts).get();
    final sharedCard = cards.singleWhere(
      (card) => card.front == 'Shared question',
    );

    expect(courses, hasLength(2));
    expect(
      courses.singleWhere((course) => course.name == 'Test course').description,
      'Local description',
    );
    expect(topics, hasLength(2));
    expect(cards, hasLength(3));
    expect(sharedCard.box, 4);
    expect(attempts, hasLength(1));
    expect(attempts.single.courseId, targetCourseId);
    expect(attempts.single.topicId, targetTopicId);
  });
}
