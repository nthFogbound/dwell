import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/quiz_repository.dart';
import '../courses/courses_provider.dart';
import 'quiz_screen.dart';

import '../../shared/widgets/status_views.dart';

class QuizSetupScreen extends StatefulWidget {
  const QuizSetupScreen({super.key});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  int? _courseId;
  int? _topicId; // null = all topics in the course
  List<Topic> _topics = [];
  int _cardCount = 0;

  Future<void> _selectCourse(int courseId) async {
    final repository = context.read<QuizRepository>();
    setState(() {
      _courseId = courseId;
      _topicId = null;
      _topics = [];
      _cardCount = 0;
    });
    final topics = await repository.topicsForCourse(courseId);
    final count = await repository.countCards(courseId: courseId);
    // Ignore the result if the user switched course while we were loading.
    if (!mounted || _courseId != courseId) return;
    setState(() {
      _topics = topics;
      _cardCount = count;
    });
  }

  Future<void> _selectTopic(int? topicId) async {
    final courseId = _courseId;
    if (courseId == null) return;
    final repository = context.read<QuizRepository>();
    setState(() => _topicId = topicId);
    final count = await repository.countCards(
      courseId: courseId,
      topicId: topicId,
    );
    if (!mounted || _topicId != topicId) return;
    setState(() => _cardCount = count);
  }

  void _start() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(courseId: _courseId!, topicId: _topicId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final coursesProvider = context.watch<CoursesProvider>();

    // Same page structure as CoursesScreen: padded column, heading, then
    // an Expanded body. No Scaffold/AppBar, because AppShell provides the frame.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quiz', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Expanded(child: _buildContent(context, coursesProvider)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CoursesProvider coursesProvider) {
    if (coursesProvider.isLoading) return const LoadingView();
    if (coursesProvider.error != null) {
      return ErrorView(error: coursesProvider.error!);
    }
    if (coursesProvider.courses.isEmpty) {
      return const EmptyState(
        message: 'Create a course and add flashcards to start a quiz.',
        icon: Icons.quiz_outlined,
      );
    }

    final theme = Theme.of(context);
    final canStart =
        _courseId != null && _cardCount >= QuizRepository.optionsPerQuestion;

    return SingleChildScrollView(
      child: SizedBox(
        width: double.infinity, // full width, like the Courses cards
        child: Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose what to be quizzed on',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: DropdownMenu<int>(
                        label: const Text('Course'),
                        expandedInsets: EdgeInsets.zero,
                        dropdownMenuEntries: [
                          for (final course in coursesProvider.courses)
                            DropdownMenuEntry(
                              value: course.id,
                              label: course.name,
                            ),
                        ],
                        onSelected: (id) {
                          if (id != null) _selectCourse(id);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownMenu<int?>(
                        // New key when the course changes, so the old topic
                        // choice resets.
                        key: ValueKey(_courseId),
                        enabled: _courseId != null,
                        label: const Text('Topic (optional)'),
                        expandedInsets: EdgeInsets.zero,
                        initialSelection: null,
                        dropdownMenuEntries: [
                          const DropdownMenuEntry<int?>(
                            value: null,
                            label: 'All topics',
                          ),
                          for (final topic in _topics)
                            DropdownMenuEntry<int?>(
                              value: topic.id,
                              label: topic.name,
                            ),
                        ],
                        onSelected: _selectTopic,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_courseId != null)
                  Text(
                    canStart
                        ? '$_cardCount flashcards available (up to 10 questions)'
                        : 'Need at least ${QuizRepository.optionsPerQuestion} '
                              'flashcards to start a quiz ($_cardCount available)',
                    style: theme.textTheme.bodyMedium,
                  ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: canStart ? _start : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start quiz'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}