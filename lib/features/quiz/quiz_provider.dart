import 'package:flutter/foundation.dart';

import '../../data/repositories/quiz_repository.dart';

enum QuizStatus { loading, notEnoughCards, inProgress, finished }

class QuizProvider extends ChangeNotifier {
  QuizProvider(
    this._repository, {
    required this.courseId,
    this.topicId,
    this.questionCount = 10,
  });

  final QuizRepository _repository;
  final int courseId;
  final int? topicId; // null = whole course
  final int questionCount;

  QuizStatus _status = QuizStatus.loading;
  List<QuizQuestion> _questions = [];
  int _currentIndex = 0;
  int? _selectedIndex; // null until the user answers the current question
  int _correctCount = 0;
  bool _disposed = false;

  QuizStatus get status => _status;
  int get totalQuestions => _questions.length;
  int get currentNumber => _currentIndex + 1; // 1-based, for "Question 3 of 10"
  int get correctCount => _correctCount;
  int? get selectedIndex => _selectedIndex;
  bool get isAnswered => _selectedIndex != null;
  bool get isLastQuestion => _currentIndex == _questions.length - 1;
  QuizQuestion get currentQuestion => _questions[_currentIndex];

  /// Call once when the quiz screen opens.
  Future<void> start() async {
    final questions = await _repository.buildQuiz(
      courseId: courseId,
      topicId: topicId,
      questionCount: questionCount,
    );
    _questions = questions;
    _status = questions.isEmpty
        ? QuizStatus.notEnoughCards
        : QuizStatus.inProgress;
    _notify();
  }

  /// The user taps an option. Ignored if already answered.
  void selectAnswer(int index) {
    if (_status != QuizStatus.inProgress || isAnswered) return;
    _selectedIndex = index;
    if (index == currentQuestion.correctIndex) _correctCount++;
    _notify();
  }

  /// Moves to the next question, or finishes the quiz after the last one.
  Future<void> next() async {
    if (_status != QuizStatus.inProgress || !isAnswered) return;

    if (isLastQuestion) {
      // Flip the status first so a double-tap can't save the attempt twice.
      _status = QuizStatus.finished;
      _notify();
      await _repository.saveAttempt(
        courseId: courseId,
        topicId: topicId,
        totalQuestions: totalQuestions,
        correctAnswers: _correctCount,
      );
    } else {
      _currentIndex++;
      _selectedIndex = null;
      _notify();
    }
  }

  // Async work (loading, saving) can finish after the screen is closed.
  // Calling notifyListeners() on a disposed notifier throws, so we guard it.
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
