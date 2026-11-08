import 'package:drift/drift.dart';

import '../database/app_database.dart';
import 'duplicate_name_exception.dart';

class TopicRepository {
  TopicRepository(this._db);

  final AppDatabase _db;

  /// Live list of one course's topics, sorted by name.
  Stream<List<Topic>> watchTopics(int courseId) {
    return (_db.select(_db.topics)
          ..where((t) => t.courseId.equals(courseId))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch();
  }

  /// True if another topic in the same course already uses this name
  /// (ignoring case and surrounding spaces).
  Future<bool> isNameTaken({
    required int courseId,
    required String name,
    int? excludeId,
  }) async {
    final wanted = name.trim().toLowerCase();
    final topics = await (_db.select(
      _db.topics,
    )..where((t) => t.courseId.equals(courseId))).get();
    return topics.any(
      (t) => t.id != excludeId && t.name.toLowerCase() == wanted,
    );
  }

  Future<int> addTopic({required int courseId, required String name}) async {
    if (await isNameTaken(courseId: courseId, name: name)) {
      throw const DuplicateNameException(
        'This course already has a topic with this name.',
      );
    }
    return _db
        .into(_db.topics)
        .insert(TopicsCompanion.insert(courseId: courseId, name: name.trim()));
  }

  Future<int> updateTopic({required int id, required String name}) async {
    // updateTopic only receives the id, so look up which course it belongs to.
    final topic = await (_db.select(
      _db.topics,
    )..where((t) => t.id.equals(id))).getSingle();
    if (await isNameTaken(
      courseId: topic.courseId,
      name: name,
      excludeId: id,
    )) {
      throw const DuplicateNameException(
        'This course already has a topic with this name.',
      );
    }
    return (_db.update(_db.topics)..where((t) => t.id.equals(id))).write(
      TopicsCompanion(name: Value(name.trim())),
    );
  }

  /// Also deletes the topic's flashcards (cascade). Past quiz attempts for
  /// this topic are kept, with their topic cleared (set null).
  Future<int> deleteTopic(int id) {
    return (_db.delete(_db.topics)..where((t) => t.id.equals(id))).go();
  }
}