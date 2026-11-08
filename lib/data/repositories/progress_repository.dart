import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// Card statistics for one course.
class CourseProgress {
  const CourseProgress({
    required this.course,
    required this.totalCards,
    required this.masteredCards,
  });

  final Course course;
  final int totalCards;
  final int masteredCards;

  /// 0.0 to 1.0. Zero when the course has no cards (avoids dividing by 0).
  double get masteredFraction =>
      totalCards == 0 ? 0 : masteredCards / totalCards;
}

/// One finished quiz, joined with names for display.
class QuizHistoryEntry {
  const QuizHistoryEntry({
    required this.courseName,
    required this.topicName,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.takenAt,
  });

  final String courseName;
  final String? topicName; // null = whole course
  final int totalQuestions;
  final int correctAnswers;
  final DateTime takenAt;

  double get scoreFraction =>
      totalQuestions == 0 ? 0 : correctAnswers / totalQuestions;
}

class ProgressRepository {
  ProgressRepository(this._db);

  final AppDatabase _db;

  /// A card in this Leitner box or higher counts as "mastered".
  static const masteredBox = 4;

  /// Per-course card counts. Courses with no cards still appear (with 0).
  Stream<List<CourseProgress>> watchCourseProgress() {
    final cards = _db.flashcards;
    final total = cards.id.count();
    final mastered = cards.id.count(
      filter: cards.box.isBiggerOrEqualValue(masteredBox),
    );

    // Courses -> Topics -> Flashcards. LEFT joins keep empty courses/topics.
    // useColumns: false = only use the joined tables for counting, don't
    // read their columns.
    final query =
        _db.select(_db.courses).join([
            leftOuterJoin(
              _db.topics,
              _db.topics.courseId.equalsExp(_db.courses.id),
              useColumns: false,
            ),
            leftOuterJoin(
              cards,
              cards.topicId.equalsExp(_db.topics.id),
              useColumns: false,
            ),
          ])
          ..addColumns([total, mastered])
          ..groupBy([_db.courses.id])
          ..orderBy([OrderingTerm.asc(_db.courses.name)]);

    return query.watch().map(
      (rows) => rows
          .map(
            (row) => CourseProgress(
              course: row.readTable(_db.courses),
              totalCards: row.read(total) ?? 0,
              masteredCards: row.read(mastered) ?? 0,
            ),
          )
          .toList(),
    );
  }

  /// The most recent quiz attempts, newest first.
  Stream<List<QuizHistoryEntry>> watchRecentAttempts({int limit = 20}) {
    final attempts = _db.quizAttempts;

    final query =
        _db.select(attempts).join([
            innerJoin(_db.courses, _db.courses.id.equalsExp(attempts.courseId)),
            // LEFT join: topicId is null for whole-course quizzes.
            leftOuterJoin(
              _db.topics,
              _db.topics.id.equalsExp(attempts.topicId),
            ),
          ])
          ..orderBy([
            OrderingTerm.desc(attempts.takenAt),
            OrderingTerm.desc(
              attempts.id,
            ), // tie-break for same-second attempts
          ])
          ..limit(limit);

    return query.watch().map(
      (rows) => rows.map((row) {
        final attempt = row.readTable(attempts);
        return QuizHistoryEntry(
          courseName: row.readTable(_db.courses).name,
          topicName: row.readTableOrNull(_db.topics)?.name,
          totalQuestions: attempt.totalQuestions,
          correctAnswers: attempt.correctAnswers,
          takenAt: attempt.takenAt,
        );
      }).toList(),
    );
  }
}
