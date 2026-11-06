import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/topic_repository.dart';

/// State for the topics of ONE course. A new instance is created each time
/// a course detail page opens, and disposed when it closes.
class TopicsProvider extends ChangeNotifier {
  TopicsProvider(this._repository, this.courseId) {
    _subscription = _repository.watchTopics(courseId).listen(
      (topics) {
        _topics = topics;
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

  final TopicRepository _repository;
  final int courseId;
  late final StreamSubscription<List<Topic>> _subscription;

  List<Topic> _topics = [];
  bool _isLoading = true;
  Object? _error;

  List<Topic> get topics => _topics;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> addTopic(String name) =>
      _repository.addTopic(courseId: courseId, name: name);

  Future<void> updateTopic({required int id, required String name}) =>
      _repository.updateTopic(id: id, name: name);

  Future<void> deleteTopic(int id) => _repository.deleteTopic(id);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}