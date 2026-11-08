import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';

/// State for the flashcards of ONE topic. A new instance is created each time
/// a topic's flashcard screen opens, and disposed when it closes.
class FlashcardsProvider extends ChangeNotifier {
  FlashcardsProvider(this._repository, this.topicId) {
    _subscription = _repository
        .watchFlashcards(topicId)
        .listen(
          (flashcards) {
            _flashcards = flashcards;
            _isLoading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object error) {
            _error = error;
            _isLoading = false;
            notifyListeners();
          },
        );
  }

  final FlashcardRepository _repository;
  final int topicId;
  late final StreamSubscription<List<Flashcard>> _subscription;

  List<Flashcard> _flashcards = [];
  bool _isLoading = true;
  Object? _error;

  List<Flashcard> get flashcards => _flashcards;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> addFlashcard({required String front, required String back}) =>
      _repository.addFlashcard(topicId: topicId, front: front, back: back);

  Future<void> updateFlashcard({
    required int id,
    required String front,
    required String back,
  }) => _repository.updateFlashcard(id: id, front: front, back: back);

  Future<void> deleteFlashcard(int id) => _repository.deleteFlashcard(id);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
