import 'dart:math';

import 'package:drift/drift.dart';

import '../database/app_database.dart';

/// One multiple-choice question built from a flashcard.
class QuizQuestion {
  const QuizQuestion({
    required this.flashcardId,
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  final int flashcardId;
  final String prompt; // the card's front
  final List<String> options; // card backs, shuffled
  final int correctIndex;
}

class QuizRepository {
  QuizRepository(this._db, {Random? random}) : _random = random ?? Random();

  final AppDatabase _db;
  final Random _random;

  static const optionsPerQuestion = 4;

  /// Flashcards in a course, or in one topic if [topicId] is given.
  Future<List<Flashcard>> _cardsFor({
    required int courseId,
    int? topicId,
  }) async {
    final query = _db.select(_db.flashcards).join([
      innerJoin(
        _db.topics,
        _db.topics.id.equalsExp(_db.flashcards.topicId),
      ),
    ]);

    // Combine into one condition so both filters apply together.
    Expression<bool> condition = _db.topics.courseId.equals(courseId);
    if (topicId != null) {
      condition = condition & _db.flashcards.topicId.equals(topicId);
    }
    query.where(condition);

    final rows = await query.get();
    return rows.map((row) => row.readTable(_db.flashcards)).toList();
  }

  /// How many cards a quiz could use (the UI can show "need at least 4").
  Future<int> countCards({required int courseId, int? topicId}) async =>
      (await _cardsFor(courseId: courseId, topicId: topicId)).length;

  /// Builds up to [questionCount] questions. Returns fewer (or none) if the
  /// scope doesn't have enough cards with distinct answers.
  Future<List<QuizQuestion>> buildQuiz({
    required int courseId,
    int? topicId,
    int questionCount = 10,
  }) async {
    final cards = await _cardsFor(courseId: courseId, topicId: topicId);
    cards.shuffle(_random);

    final questions = <QuizQuestion>[];
    for (final card in cards) {
      if (questions.length == questionCount) break;

      // Wrong options: other cards' backs, no duplicates, never the answer.
      final distractors = cards
          .map((c) => c.back)
          .where((back) => back != card.back)
          .toSet()
          .toList()
        ..shuffle(_random);
      if (distractors.length < optionsPerQuestion - 1) continue;

      final options = [card.back, ...distractors.take(optionsPerQuestion - 1)]
        ..shuffle(_random);

      questions.add(QuizQuestion(
        flashcardId: card.id,
        prompt: card.front,
        options: options,
        correctIndex: options.indexOf(card.back),
      ));
    }
    return questions;
  }

  Future<void> saveAttempt({
    required int courseId,
    int? topicId,
    required int totalQuestions,
    required int correctAnswers,
  }) {
    return _db.into(_db.quizAttempts).insert(
          QuizAttemptsCompanion.insert(
            courseId: courseId,
            topicId: Value(topicId),
            totalQuestions: totalQuestions,
            correctAnswers: correctAnswers,
          ),
        );
  }
  
  /// Topics in a course, for the quiz setup dropdown.
  Future<List<Topic>> topicsForCourse(int courseId) =>
      (_db.select(_db.topics)..where((t) => t.courseId.equals(courseId))).get();
}