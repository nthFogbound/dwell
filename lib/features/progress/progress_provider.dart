import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/repositories/progress_repository.dart';

class ProgressProvider extends ChangeNotifier {
  ProgressProvider(this._repository) {
    _courseSubscription = _repository.watchCourseProgress().listen((progress) {
      _courseProgress = progress;
      _coursesLoaded = true;
      _error = null;
      notifyListeners();
    }, onError: _onError);
    _historySubscription = _repository.watchRecentAttempts().listen((history) {
      _history = history;
      _historyLoaded = true;
      _error = null;
      notifyListeners();
    }, onError: _onError);
  }

  final ProgressRepository _repository;
  late final StreamSubscription<List<CourseProgress>> _courseSubscription;
  late final StreamSubscription<List<QuizHistoryEntry>> _historySubscription;

  List<CourseProgress> _courseProgress = [];
  List<QuizHistoryEntry> _history = [];
  bool _coursesLoaded = false;
  bool _historyLoaded = false;
  Object? _error;

  List<CourseProgress> get courseProgress => _courseProgress;
  List<QuizHistoryEntry> get history => _history;
  Object? get error => _error;

  /// Loading until both streams have delivered their first result.
  bool get isLoading => _error == null && !(_coursesLoaded && _historyLoaded);

  int get totalCards => _courseProgress.fold(0, (sum, c) => sum + c.totalCards);
  int get masteredCards =>
      _courseProgress.fold(0, (sum, c) => sum + c.masteredCards);

  double get overallMasteredFraction =>
      totalCards == 0 ? 0 : masteredCards / totalCards;

  /// Accuracy across the loaded recent quizzes only (not all-time).
  /// Null when no quizzes have been taken yet.
  double? get recentAccuracy {
    final questions = _history.fold(0, (sum, h) => sum + h.totalQuestions);
    if (questions == 0) return null;
    final correct = _history.fold(0, (sum, h) => sum + h.correctAnswers);
    return correct / questions;
  }

  void _onError(Object error) {
    _error = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _courseSubscription.cancel();
    _historySubscription.cancel();
    super.dispose();
  }
}
