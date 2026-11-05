import 'package:flutter/material.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/flashcards/flashcards_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/quiz/quiz_screen.dart';

/// The main layout: a navigation rail on the left, the active screen on the right.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  // Temporary: Step 4 moves this into Provider.
  int _selectedIndex = 0;

  static const _screens = <Widget>[
    CoursesScreen(),
    FlashcardsScreen(),
    QuizScreen(),
    ProgressScreen(),
  ];

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (i) => setState(() => _selectedIndex = i),
            labelType: NavigationRailLabelType.all,
            destinations: _destinations,
          ),
          const VerticalDivider(width: 1),
          // Expanded makes the screen fill all remaining width.
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}