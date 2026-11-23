import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/database/app_database.dart';

class BackupService {
  BackupService(this._db);

  final AppDatabase _db;

  Future<Directory> _backupDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docsDir.path}${Platform.pathSeparator}dwell_backups',
    );
    await dir.create(recursive: true);
    return dir;
  }

  Future<String> exportData(String directoryPath) async {
    final courses = await _db.select(_db.courses).get();
    final topics = await _db.select(_db.topics).get();
    final flashcards = await _db.select(_db.flashcards).get();
    final attempts = await _db.select(_db.quizAttempts).get();

    final dir = Directory(directoryPath);
    await dir.create(recursive: true);
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File(
      '${dir.path}${Platform.pathSeparator}dwell_backup_$stamp.json',
    );
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'courses': courses
            .map(
              (course) => {
                'id': course.id,
                'name': course.name,
                'description': course.description,
                'createdAt': course.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'topics': topics
            .map(
              (topic) => {
                'id': topic.id,
                'courseId': topic.courseId,
                'name': topic.name,
                'createdAt': topic.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'flashcards': flashcards
            .map(
              (card) => {
                'id': card.id,
                'topicId': card.topicId,
                'front': card.front,
                'back': card.back,
                'tags': card.tags,
                'box': card.box,
                'dueAt': card.dueAt.toIso8601String(),
                'lastReviewedAt': card.lastReviewedAt?.toIso8601String(),
                'createdAt': card.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'quizAttempts': attempts
            .map(
              (attempt) => {
                'id': attempt.id,
                'courseId': attempt.courseId,
                'topicId': attempt.topicId,
                'totalQuestions': attempt.totalQuestions,
                'correctAnswers': attempt.correctAnswers,
                'takenAt': attempt.takenAt.toIso8601String(),
              },
            )
            .toList(),
      }),
    );
    return file.path;
  }

  Future<void> importData(String filePath) async {
    final payload = jsonDecode(await File(filePath).readAsString());
    if (payload is! Map<String, dynamic> || payload['version'] != 1) {
      throw const FormatException('Unsupported backup format.');
    }

    final courses = _readRows(payload, 'courses');
    final topics = _readRows(payload, 'topics');
    final flashcards = _readRows(payload, 'flashcards');
    final attempts = _readRows(payload, 'quizAttempts');

    await _db.transaction(() async {
      final courseIds = <int, int>{};
      final coursesByName = <String, int>{
        for (final course in await _db.select(_db.courses).get())
          _normalizedName(course.name): course.id,
      };

      for (final row in courses) {
        final backupId = _requiredInt(row, 'id');
        if (courseIds.containsKey(backupId)) {
          throw const FormatException('Duplicate course ID in backup.');
        }

        final name = _requiredName(row, 'name');
        final key = _normalizedName(name);
        final existingId = coursesByName[key];
        if (existingId != null) {
          courseIds[backupId] = existingId;
          continue;
        }

        final description = row['description'];
        if (description != null && description is! String) {
          throw const FormatException('Invalid course description in backup.');
        }
        final id = await _db
            .into(_db.courses)
            .insert(
              CoursesCompanion.insert(
                name: name,
                description: Value(description as String?),
                createdAt: Value(_requiredDateTime(row, 'createdAt')),
              ),
            );
        courseIds[backupId] = id;
        coursesByName[key] = id;
      }

      final topicIds = <int, int>{};
      final topicsByName = <(int, String), int>{
        for (final topic in await _db.select(_db.topics).get())
          (topic.courseId, _normalizedName(topic.name)): topic.id,
      };

      for (final row in topics) {
        final backupId = _requiredInt(row, 'id');
        if (topicIds.containsKey(backupId)) {
          throw const FormatException('Duplicate topic ID in backup.');
        }

        final backupCourseId = _requiredInt(row, 'courseId');
        final courseId = courseIds[backupCourseId];
        if (courseId == null) {
          throw const FormatException('Topic references a missing course.');
        }

        final name = _requiredName(row, 'name');
        final key = (courseId, _normalizedName(name));
        final existingId = topicsByName[key];
        if (existingId != null) {
          topicIds[backupId] = existingId;
          continue;
        }

        final id = await _db
            .into(_db.topics)
            .insert(
              TopicsCompanion.insert(
                courseId: courseId,
                name: name,
                createdAt: Value(_requiredDateTime(row, 'createdAt')),
              ),
            );
        topicIds[backupId] = id;
        topicsByName[key] = id;
      }

      final flashcardKeys = <(int, String, String, String)>{
        for (final card in await _db.select(_db.flashcards).get())
          (card.topicId, card.front, card.back, card.tags),
      };

      for (final row in flashcards) {
        final backupTopicId = _requiredInt(row, 'topicId');
        final topicId = topicIds[backupTopicId];
        if (topicId == null) {
          throw const FormatException('Flashcard references a missing topic.');
        }

        final front = _requiredString(row, 'front');
        final back = _requiredString(row, 'back');
        final tags = row['tags'] ?? '';
        if (tags is! String) {
          throw const FormatException('Invalid flashcard tags in backup.');
        }
        final key = (topicId, front, back, tags);
        if (flashcardKeys.contains(key)) continue;

        final box = row['box'] ?? 1;
        if (box is! int) {
          throw const FormatException('Invalid flashcard box in backup.');
        }
        final lastReviewedAt = row['lastReviewedAt'] == null
            ? null
            : _requiredDateTime(row, 'lastReviewedAt');
        await _db
            .into(_db.flashcards)
            .insert(
              FlashcardsCompanion.insert(
                topicId: topicId,
                front: front,
                back: back,
                tags: Value(tags),
                box: Value(box),
                dueAt: Value(_requiredDateTime(row, 'dueAt')),
                lastReviewedAt: Value(lastReviewedAt),
                createdAt: Value(_requiredDateTime(row, 'createdAt')),
              ),
            );
        flashcardKeys.add(key);
      }

      final attemptKeys = <(int, int?, int, int, DateTime)>{
        for (final attempt in await _db.select(_db.quizAttempts).get())
          (
            attempt.courseId,
            attempt.topicId,
            attempt.totalQuestions,
            attempt.correctAnswers,
            attempt.takenAt.toUtc(),
          ),
      };

      for (final row in attempts) {
        final backupCourseId = _requiredInt(row, 'courseId');
        final courseId = courseIds[backupCourseId];
        if (courseId == null) {
          throw const FormatException(
            'Quiz attempt references a missing course.',
          );
        }

        final backupTopicId = row['topicId'];
        int? topicId;
        if (backupTopicId != null) {
          if (backupTopicId is! int) {
            throw const FormatException('Invalid quiz topic ID in backup.');
          }
          topicId = topicIds[backupTopicId];
          if (topicId == null) {
            throw const FormatException(
              'Quiz attempt references a missing topic.',
            );
          }
        }

        final totalQuestions = _requiredInt(row, 'totalQuestions');
        final correctAnswers = _requiredInt(row, 'correctAnswers');
        final takenAt = _requiredDateTime(row, 'takenAt');
        final key = (
          courseId,
          topicId,
          totalQuestions,
          correctAnswers,
          takenAt.toUtc(),
        );
        if (attemptKeys.contains(key)) continue;

        await _db
            .into(_db.quizAttempts)
            .insert(
              QuizAttemptsCompanion.insert(
                courseId: courseId,
                topicId: Value(topicId),
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                takenAt: Value(takenAt),
              ),
            );
        attemptKeys.add(key);
      }
    });
  }

  List<Map<String, dynamic>> _readRows(
    Map<String, dynamic> payload,
    String field,
  ) {
    final value = payload[field];
    if (value is! List) {
      throw FormatException('Backup field "$field" must be a list.');
    }
    return value.map((row) {
      if (row is! Map<String, dynamic>) {
        throw FormatException('Backup field "$field" contains an invalid row.');
      }
      return row;
    }).toList();
  }

  int _requiredInt(Map<String, dynamic> row, String field) {
    final value = row[field];
    if (value is! int) {
      throw FormatException('Backup field "$field" must be an integer.');
    }
    return value;
  }

  String _requiredString(Map<String, dynamic> row, String field) {
    final value = row[field];
    if (value is! String || value.isEmpty) {
      throw FormatException(
        'Backup field "$field" must be a non-empty string.',
      );
    }
    return value;
  }

  String _requiredName(Map<String, dynamic> row, String field) {
    final value = _requiredString(row, field).trim();
    if (value.isEmpty) {
      throw FormatException('Backup field "$field" must be a non-empty name.');
    }
    return value;
  }

  DateTime _requiredDateTime(Map<String, dynamic> row, String field) {
    final value = row[field];
    if (value is! String) {
      throw FormatException('Backup field "$field" must be a date.');
    }
    final date = DateTime.tryParse(value);
    if (date == null) {
      throw FormatException('Backup field "$field" must be a valid date.');
    }
    return date;
  }

  String _normalizedName(String name) => name.trim().toLowerCase();

  Future<bool> restoreLatest() async {
    final rootDir = await getApplicationDocumentsDirectory();
    final backupDir = await _backupDirectory();
    final directories = [rootDir, backupDir];
    final candidates = <File>[];

    for (final directory in directories) {
      if (!directory.existsSync()) continue;
      candidates.addAll(
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('dwell_backup_'))
            .toList(),
      );
    }

    if (candidates.isEmpty) return false;

    candidates.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    final newest = candidates.first;
    final payload = jsonDecode(await newest.readAsString());
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Backup file is not valid JSON data.');
    }

    final data = payload;

    await _db.transaction(() async {
      await (_db.delete(_db.quizAttempts)).go();
      await (_db.delete(_db.flashcards)).go();
      await (_db.delete(_db.topics)).go();
      await (_db.delete(_db.courses)).go();

      final courseMap = <int, int>{};
      for (final item in (data['courses'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final id = await _db
            .into(_db.courses)
            .insert(
              CoursesCompanion.insert(
                name: row['name'] as String,
                description: Value(row['description'] as String?),
                createdAt: Value(DateTime.parse(row['createdAt'] as String)),
              ),
            );
        courseMap[row['id'] as int] = id;
      }

      final topicMap = <int, int>{};
      for (final item in (data['topics'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final courseId = courseMap[row['courseId'] as int];
        if (courseId == null) continue;
        final id = await _db
            .into(_db.topics)
            .insert(
              TopicsCompanion.insert(
                courseId: courseId,
                name: row['name'] as String,
                createdAt: Value(DateTime.parse(row['createdAt'] as String)),
              ),
            );
        topicMap[row['id'] as int] = id;
      }

      for (final item in (data['flashcards'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final topicId = topicMap[row['topicId'] as int];
        if (topicId == null) continue;
        await _db
            .into(_db.flashcards)
            .insert(
              FlashcardsCompanion.insert(
                topicId: topicId,
                front: row['front'] as String,
                back: row['back'] as String,
                tags: Value((row['tags'] as String?) ?? ''),
                box: Value((row['box'] as int?) ?? 1),
                dueAt: Value(DateTime.parse(row['dueAt'] as String)),
                lastReviewedAt: Value(
                  row['lastReviewedAt'] == null
                      ? null
                      : DateTime.parse(row['lastReviewedAt'] as String),
                ),
                createdAt: Value(DateTime.parse(row['createdAt'] as String)),
              ),
            );
      }

      for (final item in (data['quizAttempts'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final courseId = courseMap[row['courseId'] as int];
        final topicId = row['topicId'] == null
            ? null
            : topicMap[row['topicId'] as int];
        if (courseId == null) continue;
        await _db
            .into(_db.quizAttempts)
            .insert(
              QuizAttemptsCompanion.insert(
                courseId: courseId,
                topicId: Value(topicId),
                totalQuestions: row['totalQuestions'] as int,
                correctAnswers: row['correctAnswers'] as int,
                takenAt: Value(DateTime.parse(row['takenAt'] as String)),
              ),
            );
      }
    });

    return true;
  }
}
