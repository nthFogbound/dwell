import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/navigation/navigation_provider.dart';
import 'data/database/app_database.dart';
import 'data/repositories/course_repository.dart';
import 'features/courses/courses_provider.dart';
import 'data/repositories/topic_repository.dart';
import 'data/repositories/flashcard_repository.dart';
import 'data/repositories/quiz_repository.dart';
import 'data/repositories/progress_repository.dart';
import 'features/progress/progress_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        Provider<CourseRepository>(
          create: (context) => CourseRepository(context.read<AppDatabase>()),
        ),
        ChangeNotifierProvider<CoursesProvider>(
          create: (context) =>
              CoursesProvider(context.read<CourseRepository>()),
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
          create: (context) => ProgressProvider(context.read<ProgressRepository>()),
        ),
      ],
      child: const DwellApp(),
    ),
  );
}
