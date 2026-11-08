import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';

/// State for ONE review session of one topic. Created when the review
/// screen opens, disposed when it closes.
class ReviewProvider extends ChangeNotifier {
  ReviewProvider(this._repository, this.topicId) {
    _load();
  }

  final FlashcardRepository _repository;
  final int topicId;

  List<Flashcard> _queue = [];
  int _index = 0;
  bool _isLoading = true;
  bool _isRevealed = false;
  bool _isSaving = false;
  int _rememberedCount = 0;
  int _missedCount = 0;
  Object? _error;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  bool get isRevealed => _isRevealed;
  Object? get error => _error;
  int get total => _queue.length;
  int get position => _index; // cards finished so far
  int get rememberedCount => _rememberedCount;
  int get missedCount => _missedCount;
  bool get isComplete =>
      !_isLoading && _queue.isNotEmpty && _index >= _queue.length;
  bool get hasNothingDue => !_isLoading && _queue.isEmpty;
  Flashcard? get currentCard =>
      (_isLoading || _index >= _queue.length) ? null : _queue[_index];

  Future<void> _load() async {
    try {
      _queue = await _repository.getDueCards(topicId);
    } catch (e) {
      _error = e;
    }
    _isLoading = false;
    if (!_disposed) notifyListeners();
  }

  /// Shows the answer. Only reveals (never hides), so a repeated
  /// keypress or click can't flip it back.
  void reveal() {
    if (currentCard == null || _isRevealed) return;
    _isRevealed = true;
    notifyListeners();
  }

  /// Saves the rating and advances. Ignored until the answer is revealed.
  Future<void> answer({required bool remembered}) async {
    final card = currentCard;
    if (card == null || !_isRevealed || _isSaving) return;

    _isSaving = true; // blocks double-clicks while the write is in progress
    try {
      await _repository.recordReview(id: card.id, remembered: remembered);
      if (remembered) {
        _rememberedCount++;
      } else {
        _missedCount++;
      }
      _index++;
      _isRevealed = false;
    } catch (e) {
      _error = e;
    } finally {
      _isSaving = false;
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true; // the async work above may finish after the screen closes
    super.dispose();
  }
}
