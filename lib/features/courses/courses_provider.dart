import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/course_repository.dart';

class CoursesProvider extends ChangeNotifier {
  CoursesProvider(this._repository) {
    _subscription = _repository.watchCourses().listen(
      (courses) {
        _courses = courses;
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

  final CourseRepository _repository;
  late final StreamSubscription<List<Course>> _subscription;

  List<Course> _courses = [];
  bool _isLoading = true;
  Object? _error;

  List<Course> get courses => _courses;
  bool get isLoading => _isLoading;
  Object? get error => _error;

  Future<void> addCourse({required String name, String? description}) =>
      _repository.addCourse(name: name, description: description);

  Future<void> updateCourse({
    required int id,
    required String name,
    String? description,
  }) => _repository.updateCourse(id: id, name: name, description: description);

  Future<void> deleteCourse(int id) => _repository.deleteCourse(id);

  Future<bool> isNameTaken(String name, {int? excludeId}) =>
      _repository.isNameTaken(name, excludeId: excludeId);

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
