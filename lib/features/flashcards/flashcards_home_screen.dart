import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/topic_repository.dart';
import '../courses/courses_provider.dart';
import 'flashcards_screen.dart';
import '../courses/topics_provider.dart';

/// The Flashcards tab: pick a course, then a topic, to open its flashcards.
class FlashcardsHomeScreen extends StatefulWidget {
  const FlashcardsHomeScreen({super.key});

  @override
  State<FlashcardsHomeScreen> createState() => _FlashcardsHomeScreenState();
}

class _FlashcardsHomeScreenState extends State<FlashcardsHomeScreen> {
  Course? _course;

  @override
  Widget build(BuildContext context) {
    final coursesProvider = context.watch<CoursesProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Flashcards')),
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
      return const Text('Create a course and add topics to get started.');
    }

    final course = _course;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose a course, then a topic',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        DropdownMenu<Course>(
          label: const Text('Course'),
          expandedInsets: EdgeInsets.zero,
          dropdownMenuEntries: [
            for (final c in coursesProvider.courses)
              DropdownMenuEntry(value: c, label: c.name),
          ],
          onSelected: (c) => setState(() => _course = c),
        ),
        const SizedBox(height: 16),
        if (course != null)
          Expanded(
            // The key makes Provider build a NEW TopicsProvider when the
            // course changes. Without it, the old course's topics would stay.
            child: ChangeNotifierProvider(
              key: ValueKey(course.id),
              create: (context) =>
                  TopicsProvider(context.read<TopicRepository>(), course.id),
              child: const _TopicList(),
            ),
          ),
      ],
    );
  }
}

class _TopicList extends StatelessWidget {
  const _TopicList();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TopicsProvider>();

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Something went wrong: ${provider.error}'));
    }
    if (provider.topics.isEmpty) {
      return const Text(
        'No topics in this course yet. Add one in the Courses tab.',
      );
    }

    return ListView.separated(
      itemCount: provider.topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final topic = provider.topics[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(topic.name),
            trailing: const Icon(Icons.chevron_right),
            onTap: () =>
                Navigator.of(context).push(FlashcardsScreen.route(topic)),
          ),
        );
      },
    );
  }
}