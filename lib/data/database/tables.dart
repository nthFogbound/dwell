import 'package:drift/drift.dart';

class Courses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get description => text().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Topics extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get courseId =>
      integer().references(Courses, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Flashcards extends Table {
  IntColumn get id => integer().autoIncrement()();

  // Deleting a topic also deletes its flashcards (same cascade pattern as Topics -> Courses).
  IntColumn get topicId =>
      integer().references(Topics, #id, onDelete: KeyAction.cascade)();

  TextColumn get front => text().withLength(min: 1, max: 1000)();
  TextColumn get back => text().withLength(min: 1, max: 2000)();

  // Leitner box (1-5). New cards start in box 1.
  IntColumn get box => integer().withDefault(const Constant(1))();

  // When the card is next due. Defaults to "now", so new cards are due immediately.
  DateTimeColumn get dueAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}