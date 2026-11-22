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
  String _searchQuery = '';
  String? _selectedTag;

  List<Flashcard> get flashcards => _flashcards;
  List<Flashcard> get filteredFlashcards {
    final query = _searchQuery.trim().toLowerCase();
    final selectedTag = _selectedTag;
    return _flashcards.where((card) {
      final tags = FlashcardRepository.parseTags(card.tags);
      final matchesText = query.isEmpty ||
          card.front.toLowerCase().contains(query) ||
          card.back.toLowerCase().contains(query) ||
          tags.any((tag) => tag.toLowerCase().contains(query));
      final matchesTag = selectedTag == null ||
          tags.any((tag) => tag.toLowerCase() == selectedTag.toLowerCase());
      return matchesText && matchesTag;
    }).toList();
  }

  List<String> get availableTags {
    final tags = <String>{};
    for (final card in _flashcards) {
      tags.addAll(FlashcardRepository.parseTags(card.tags));
    }
    final sorted = tags.toList()..sort();
    return sorted;
  }

  String get searchQuery => _searchQuery;
  String? get selectedTag => _selectedTag;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  void setSelectedTag(String? value) {
    _selectedTag = value;
    notifyListeners();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedTag = null;
    notifyListeners();
  }

  Future<void> addFlashcard({
    required String front,
    required String back,
    String? tags,
  }) => _repository.addFlashcard(
    topicId: topicId,
    front: front,
    back: back,
    tags: tags,
  );

  Future<void> updateFlashcard({
    required int id,
    required String front,
    required String back,
    String? tags,
  }) => _repository.updateFlashcard(
    id: id,
    front: front,
    back: back,
    tags: tags,
  );

  Future<void> deleteFlashcard(int id) => _repository.deleteFlashcard(id);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
