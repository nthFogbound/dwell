import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:dwell/app.dart';
import 'package:dwell/core/navigation/navigation_provider.dart';
import 'package:dwell/data/database/app_database.dart';
import 'package:dwell/data/repositories/course_repository.dart';
import 'package:dwell/data/repositories/flashcard_repository.dart';
import 'package:dwell/data/repositories/progress_repository.dart';
import 'package:dwell/data/repositories/quiz_repository.dart';
import 'package:dwell/data/repositories/topic_repository.dart';
import 'package:dwell/features/courses/courses_provider.dart';
import 'package:dwell/features/progress/progress_provider.dart';

void main() {
  testWidgets('selecting a destination changes the section', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => NavigationProvider()),
          Provider<AppDatabase>(
            create: (_) => AppDatabase(NativeDatabase.memory()),
            dispose: (_, db) => db.close(),
          ),
          Provider<CourseRepository>(
            create: (context) => CourseRepository(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider<CoursesProvider>(
            create: (context) => CoursesProvider(context.read<CourseRepository>()),
          ),
          Provider<TopicRepository>(
            create: (context) => TopicRepository(context.read<AppDatabase>()),
          ),
          Provider<FlashcardRepository>(
            create: (context) => FlashcardRepository(context.read<AppDatabase>()),
          ),
          Provider<QuizRepository>(
            create: (context) => QuizRepository(context.read<AppDatabase>()),
          ),
          Provider<ProgressRepository>(
            create: (context) => ProgressRepository(context.read<AppDatabase>()),
          ),
          ChangeNotifierProvider<ProgressProvider>(
            create: (context) =>
                ProgressProvider(context.read<ProgressRepository>()),
          ),
        ],
        child: const DwellApp(),
      ),
    );

    await tester.tap(find.text('Quiz'));
    await tester.pump();

    final context = tester.element(find.byType(DwellApp));
    expect(context.read<NavigationProvider>().current, AppSection.quiz);
  });
}
