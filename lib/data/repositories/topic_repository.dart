import 'package:drift/drift.dart';

import '../database/app_database.dart';

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

  Future<int> addTopic({required int courseId, required String name}) {
    return _db.into(_db.topics).insert(
          TopicsCompanion.insert(courseId: courseId, name: name.trim()),
        );
  }

  Future<int> updateTopic({required int id, required String name}) {
    return (_db.update(_db.topics)..where((t) => t.id.equals(id)))
        .write(TopicsCompanion(name: Value(name.trim())));
  }

  Future<int> deleteTopic(int id) {
    return (_db.delete(_db.topics)..where((t) => t.id.equals(id))).go();
  }
}