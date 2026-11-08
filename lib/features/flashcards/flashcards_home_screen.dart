import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/topic_repository.dart';
import '../courses/courses_provider.dart';
import 'flashcards_screen.dart';
import '../courses/topics_provider.dart';

import '../../shared/widgets/status_views.dart';

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

    // Same page structure as CoursesScreen: padded column, heading, Expanded body.
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Flashcards',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
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
        message: 'Create a course and add topics to get started.',
        icon: Icons.school_outlined,
      );
    }

    final course = _course;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownMenu<Course>(
          label: const Text('Course'),
          expandedInsets: EdgeInsets.zero, // fill the available width
          dropdownMenuEntries: [
            for (final c in coursesProvider.courses)
              DropdownMenuEntry(value: c, label: c.name),
          ],
          onSelected: (c) => setState(() => _course = c),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: course == null
              ? const EmptyState(
                  message: 'Choose a course to see its topics.',
                  icon: Icons.folder_open_outlined,
              )
              : ChangeNotifierProvider(
                  key: ValueKey(course.id),
                  create: (context) => TopicsProvider(
                    context.read<TopicRepository>(),
                    course.id,
                  ),
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
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(error: provider.error!);
    if (provider.topics.isEmpty) {
      return const EmptyState(
        message: 'No topics in this course yet. Add one in the Courses tab.',
        icon: Icons.folder_open_outlined,
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