import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/navigation/navigation_provider.dart';
import '../../features/courses/courses_screen.dart';
import '../../features/flashcards/flashcards_home_screen.dart';
import '../../features/progress/progress_screen.dart';
import '../../features/quiz/quiz_setup_screen.dart';
import '../../features/settings/settings_dialog.dart';
import '../../shared/widgets/content_width.dart';

/// The main layout: a navigation rail on the left, the active screen on the right.
class AppShell extends StatelessWidget {
  const AppShell({super.key});

  List<NavigationRailDestination> _destinations(BuildContext context) => [
    NavigationRailDestination(
      icon: const Icon(Icons.school_outlined),
      selectedIcon: const Icon(Icons.school),
      label: Text(AppStrings.of(context, 'Courses')),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.style_outlined),
      selectedIcon: const Icon(Icons.style),
      label: Text(AppStrings.of(context, 'Flashcards')),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.quiz_outlined),
      selectedIcon: const Icon(Icons.quiz),
      label: Text(AppStrings.of(context, 'Quiz')),
    ),
    NavigationRailDestination(
      icon: const Icon(Icons.insights_outlined),
      selectedIcon: const Icon(Icons.insights),
      label: Text(AppStrings.of(context, 'Progress')),
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
          Column(
            children: [
              Expanded(
                child: NavigationRail(
                  selectedIndex: nav.current.index,
                  onDestinationSelected: (i) => context
                      .read<NavigationProvider>()
                      .select(AppSection.values[i]),
                  labelType: NavigationRailLabelType.all,
                  destinations: _destinations(context),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => showSettingsDialog(context),
                      icon: const Icon(Icons.settings_outlined),
                    ),
                    Text(
                      AppStrings.of(context, 'Settings'),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: ContentWidth(child: _screenFor(nav.current))),
        ],
      ),
    );
  }
}
