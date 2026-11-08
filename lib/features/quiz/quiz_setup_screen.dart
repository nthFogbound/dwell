import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/quiz_repository.dart';
import '../courses/courses_provider.dart';
import 'quiz_screen.dart';

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

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _buildContent(context, coursesProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CoursesProvider coursesProvider) {
    if (coursesProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (coursesProvider.error != null) {
      return const Text('Could not load courses.');
    }
    if (coursesProvider.courses.isEmpty) {
      return const Text('Create a course and add flashcards to start a quiz.');
    }

    final theme = Theme.of(context);
    final canStart =
        _courseId != null && _cardCount >= QuizRepository.optionsPerQuestion;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose what to be quizzed on',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        DropdownMenu<int>(
          label: const Text('Course'),
          expandedInsets: EdgeInsets.zero, // fill the available width
          dropdownMenuEntries: [
            for (final course in coursesProvider.courses)
              DropdownMenuEntry(value: course.id, label: course.name),
          ],
          onSelected: (id) {
            if (id != null) _selectCourse(id);
          },
        ),
        const SizedBox(height: 16),
        DropdownMenu<int?>(
          // New key when the course changes, so the old topic choice resets.
          key: ValueKey(_courseId),
          enabled: _courseId != null,
          label: const Text('Topic (optional)'),
          expandedInsets: EdgeInsets.zero,
          initialSelection: null,
          dropdownMenuEntries: [
            const DropdownMenuEntry<int?>(value: null, label: 'All topics'),
            for (final topic in _topics)
              DropdownMenuEntry<int?>(value: topic.id, label: topic.name),
          ],
          onSelected: _selectTopic,
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
    );
  }
}
