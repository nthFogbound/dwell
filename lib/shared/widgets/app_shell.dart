import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/navigation/navigation_provider.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/flashcards/flashcards_home_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/quiz/quiz_setup_screen.dart';

/// The main layout: a navigation rail on the left, the active screen on the right.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  static const _destinations = <NavigationRailDestination>[
    NavigationRailDestination(
      icon: Icon(Icons.school_outlined),
      selectedIcon: Icon(Icons.school),
      label: Text('Courses'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.style_outlined),
      selectedIcon: Icon(Icons.style),
      label: Text('Flashcards'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.quiz_outlined),
      selectedIcon: Icon(Icons.quiz),
      label: Text('Quiz'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: Text('Progress'),
    ),
  ];

  Widget _screenFor(AppSection section) {
    switch (section) {
      case AppSection.courses:
        return const CoursesScreen();
      case AppSection.flashcards:
        return const FlashcardsHomeScreen();
      case AppSection.quiz:
        return const QuizSetupScreen();
      case AppSection.progress:
        return const ProgressScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // watch: rebuild this widget whenever NavigationProvider notifies.
    final nav = context.watch<NavigationProvider>();

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: nav.current.index,
            onDestinationSelected: (i) =>
                // read: call a method without subscribing to changes.
                context.read<NavigationProvider>().select(AppSection.values[i]),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1),
          Expanded(child: _screenFor(nav.current)),
        ],
      ),
    );
  }
}
