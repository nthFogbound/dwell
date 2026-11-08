import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'duplicate_name_exception.dart';

class CourseRepository {
  CourseRepository(this._db);

  final AppDatabase _db;

  /// Live list of courses, sorted by name. Emits a new list
  /// automatically whenever the courses table changes.
  Stream<List<Course>> watchCourses() {
    return (_db.select(
      _db.courses,
    )..orderBy([(t) => OrderingTerm.asc(t.name)])).watch();
  }

  /// True if another course already uses this name (ignoring upper/lower case
  /// and surrounding spaces). Pass [excludeId] when editing, so a course
  /// doesn't clash with itself.
  Future<bool> isNameTaken(String name, {int? excludeId}) async {
    final wanted = name.trim().toLowerCase();
    final courses = await _db.select(_db.courses).get();
    return courses.any(
      (c) => c.id != excludeId && c.name.toLowerCase() == wanted,
    );
  }

  Future<int> addCourse({required String name, String? description}) async {
    if (await isNameTaken(name)) {
      throw const DuplicateNameException(
        'A course with this name already exists.',
      );
    }
    return _db
        .into(_db.courses)
        .insert(
          CoursesCompanion.insert(
            name: name.trim(),
            description: Value(_clean(description)),
          ),
        );
  }

  Future<int> updateCourse({
    required int id,
    required String name,
    String? description,
  }) async {
    if (await isNameTaken(name, excludeId: id)) {
      throw const DuplicateNameException(
        'A course with this name already exists.',
      );
    }
    return (_db.update(_db.courses)..where((t) => t.id.equals(id))).write(
      CoursesCompanion(
        name: Value(name.trim()),
        description: Value(_clean(description)),
      ),
    );
  }

  /// Also deletes the course's topics, their flashcards and the course's
  /// quiz attempts (cascades, set up in tables.dart).
  Future<int> deleteCourse(int id) {
    return (_db.delete(_db.courses)..where((t) => t.id.equals(id))).go();
  }

  String? _clean(String? text) {
    final trimmed = text?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }
}