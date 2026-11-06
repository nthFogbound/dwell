import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app.dart';
import 'core/navigation/navigation_provider.dart';
import 'data/database/app_database.dart';
import 'data/repositories/course_repository.dart';
import 'data/repositories/topic_repository.dart';
import 'features/courses/courses_provider.dart';

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
        Provider<TopicRepository>(
          create: (context) => TopicRepository(context.read<AppDatabase>()),
        ),
        ChangeNotifierProvider<CoursesProvider>(
          create: (context) =>
              CoursesProvider(context.read<CourseRepository>()),
        ),
      ],
      child: const DwellApp(),
    ),
  );
}