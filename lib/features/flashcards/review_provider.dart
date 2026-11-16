import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/settings/settings_provider.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';

/// State for ONE review session of one topic. Created when the review
/// screen opens, disposed when it closes.
class ReviewProvider extends ChangeNotifier {
  ReviewProvider(
    this._repository,
    this.topicId, {
    this.repeatGap = MissedCardRepeatGap.afterTwoCards,
  }) {
    _sessionStartedAt = DateTime.now();
    _load();
  }

  final FlashcardRepository _repository;
  final int topicId;
  final MissedCardRepeatGap repeatGap;

  List<Flashcard> _baseQueue = [];
  List<Flashcard> _queue = [];
  int _index = 0;
  bool _isLoading = true;
  bool _isRevealed = false;
  bool _isSaving = false;
  bool _isEnded = false;
  Object? _error;
  bool _disposed = false;
  late DateTime _sessionStartedAt;
  final Set<int> _reviewedIds = {};
  final Set<int> _missedIds = {};
  final Map<int, int> _attemptsByCard = {};
  final List<_ReviewUndoEntry> _undoStack = [];

  bool get isLoading => _isLoading;
  bool get isRevealed => _isRevealed;
  bool get isEnded => _isEnded || _queueIsComplete;
  bool get canUndo => _undoStack.isNotEmpty && !_isSaving;
  Object? get error => _error;
  int get total => _baseQueue.length;
  int get position => reviewedCount;
  int get reviewedCount => _reviewedIds.length;
  int get attempts => _attemptsByCard.values.fold(0, (a, b) => a + b);
  int get rememberedCount => attempts - _missedResponseCount;
  int get missedCount => _missedResponseCount;
  int get missedCardsCount => _missedIds.length;
  int _missedResponseCount = 0;
  double get accuracy => attempts == 0 ? 0 : rememberedCount / attempts;
  Duration get elapsed => DateTime.now().difference(_sessionStartedAt);
  bool get currentCardIsRepeat =>
      currentCard != null && (_attemptsByCard[currentCard!.id] ?? 0) > 0;
  bool get isComplete => !_isLoading && isEnded;
  bool get hasNothingDue => !_isLoading && _baseQueue.isEmpty;
  Flashcard? get currentCard =>
      (_isLoading || isEnded || _index >= _queue.length)
      ? null
      : _queue[_index];
  bool get _queueIsComplete => _queue.isNotEmpty && _index >= _queue.length;

  Future<void> _load() async {
    try {
      _baseQueue = await _repository.getDueCards(topicId);
      _queue = List.of(_baseQueue);
    } catch (e) {
      _error = e;
    }
    _isLoading = false;
    if (!_disposed) notifyListeners();
  }

  /// Shows the answer. Only reveals (never hides), so a repeated
  /// keypress or click can't flip it back.
  void reveal() {
    if (currentCard == null || _isRevealed || _isSaving) return;
    _isRevealed = true;
    notifyListeners();
  }

  /// Saves the rating and advances. Ignored until the answer is revealed.
  Future<void> answer({required bool remembered}) async {
    final card = currentCard;
    if (card == null || !_isRevealed || _isSaving) return;

    _isSaving = true;
    try {
      final schedulingBefore = await _repository.recordReview(
        id: card.id,
        remembered: remembered,
      );
      _undoStack.add(
        _ReviewUndoEntry(
          schedulingBefore: schedulingBefore,
          queue: List.of(_queue),
          index: _index,
          reviewedIds: Set.of(_reviewedIds),
          missedIds: Set.of(_missedIds),
          attemptsByCard: Map.of(_attemptsByCard),
          missedResponseCount: _missedResponseCount,
        ),
      );
      if (_undoStack.length > 5) _undoStack.removeAt(0);

      _reviewedIds.add(card.id);
      _attemptsByCard.update(card.id, (count) => count + 1, ifAbsent: () => 1);
      if (!remembered) {
        _missedResponseCount++;
        _missedIds.add(card.id);
      }

      _index++;
      if (!remembered) {
        final insertionIndex = min(_index + repeatGap.cardGap, _queue.length);
        _queue.insert(insertionIndex, card);
      }
      _isRevealed = false;
      _error = null;
    } catch (e) {
      _error = e;
    } finally {
      _isSaving = false;
    }
    if (!_disposed) notifyListeners();
  }

  Future<bool> undoLastResponse() async {
    if (!canUndo) return false;
    _isSaving = true;
    final entry = _undoStack.last;
    var undone = false;
    try {
      await _repository.restoreReviewState(entry.schedulingBefore);
      _undoStack.removeLast();
      _queue = List.of(entry.queue);
      _index = entry.index;
      _reviewedIds
        ..clear()
        ..addAll(entry.reviewedIds);
      _missedIds
        ..clear()
        ..addAll(entry.missedIds);
      _attemptsByCard
        ..clear()
        ..addAll(entry.attemptsByCard);
      _missedResponseCount = entry.missedResponseCount;
      _isEnded = false;
      _isRevealed = false;
      _error = null;
      undone = true;
    } catch (e) {
      _error = e;
    } finally {
      _isSaving = false;
    }
    if (!_disposed) notifyListeners();
    return undone;
  }

  void endSession() {
    if (_isLoading || _isSaving || _isEnded) return;
    _isEnded = true;
    _isRevealed = false;
    notifyListeners();
  }

  /// Starts another round using this session's original card snapshot.
  void restart() {
    if (_isLoading || _isSaving) return;
    if (_baseQueue.isEmpty) {
      unawaited(reviewAllCards());
      return;
    }
    _queue = List.of(_baseQueue);
    _index = 0;
    _isRevealed = false;
    _isEnded = false;
    _reviewedIds.clear();
    _missedIds.clear();
    _attemptsByCard.clear();
    _missedResponseCount = 0;
    _undoStack.clear();
    _sessionStartedAt = DateTime.now();
    _error = null;
    notifyListeners();
  }

  Future<void> reviewAllCards() async {
    if (_isLoading || _isSaving || _baseQueue.isNotEmpty) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _baseQueue = await _repository.getAllCards(topicId);
      _queue = List.of(_baseQueue);
      _index = 0;
      _isRevealed = false;
      _isEnded = false;
      _reviewedIds.clear();
      _missedIds.clear();
      _attemptsByCard.clear();
      _missedResponseCount = 0;
      _undoStack.clear();
      _sessionStartedAt = DateTime.now();
    } catch (e) {
      _error = e;
    } finally {
      _isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class _ReviewUndoEntry {
  const _ReviewUndoEntry({
    required this.schedulingBefore,
    required this.queue,
    required this.index,
    required this.reviewedIds,
    required this.missedIds,
    required this.attemptsByCard,
    required this.missedResponseCount,
  });

  final Flashcard schedulingBefore;
  final List<Flashcard> queue;
  final int index;
  final Set<int> reviewedIds;
  final Set<int> missedIds;
  final Map<int, int> attemptsByCard;
  final int missedResponseCount;
}
