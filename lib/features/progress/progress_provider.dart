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
    _dailySummarySubscription = _repository.watchDailyStudySummary().listen(
      (summary) {
        _dailySummary = summary;
        _dailyLoaded = true;
        _error = null;
        notifyListeners();
      },
      onError: _onError,
    );
  }

  final ProgressRepository _repository;
  late final StreamSubscription<List<CourseProgress>> _courseSubscription;
  late final StreamSubscription<List<QuizHistoryEntry>> _historySubscription;
  late final StreamSubscription<DailyStudySummary> _dailySummarySubscription;

  List<CourseProgress> _courseProgress = [];
  List<QuizHistoryEntry> _history = [];
  DailyStudySummary _dailySummary = const DailyStudySummary(
    reviewsToday: 0,
    cardsDueToday: 0,
    cardsOverdue: 0,
  );
  bool _coursesLoaded = false;
  bool _historyLoaded = false;
  bool _dailyLoaded = false;
  Object? _error;

  List<CourseProgress> get courseProgress => _courseProgress;
  List<QuizHistoryEntry> get history => _history;
  DailyStudySummary get dailySummary => _dailySummary;
  Object? get error => _error;

  /// Loading until all streams have delivered their first result.
  bool get isLoading =>
      _error == null && !(_coursesLoaded && _historyLoaded && _dailyLoaded);

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
    _dailySummarySubscription.cancel();
    super.dispose();
  }
}
