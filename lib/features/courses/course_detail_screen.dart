import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/topic_repository.dart';
import 'topics_provider.dart';
import 'widgets/topic_form_dialog.dart';
import '../flashcards/flashcards_screen.dart';

import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/status_views.dart';
import '../../shared/widgets/content_width.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.course});

  final Course course;

  /// Opens this page with its own TopicsProvider for the given course.
  static Route<void> route(Course course) {
    return MaterialPageRoute<void>(
      builder: (context) => ChangeNotifierProvider(
        create: (context) =>
            TopicsProvider(context.read<TopicRepository>(), course.id),
        child: CourseDetailScreen(course: course),
      ),
    );
  }

  Future<void> _addTopic(BuildContext context) async {
    final provider = context.read<TopicsProvider>();
    final name = await showTopicFormDialog(context);
    if (name == null) return;
    await provider.addTopic(name);
  }

  Future<void> _editTopic(BuildContext context, Topic topic) async {
    final provider = context.read<TopicsProvider>();
    final name = await showTopicFormDialog(context, topic: topic);
    if (name == null) return;
    await provider.updateTopic(id: topic.id, name: name);
  }

  Future<void> _deleteTopic(BuildContext context, Topic topic) async {
    final provider = context.read<TopicsProvider>();
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete topic?',
      message: '"${topic.name}" will be permanently deleted.',
    );
    if (!confirmed) return;
    await provider.deleteTopic(topic.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TopicsProvider>();
    final description = course.description;

    return Scaffold(
      appBar: AppBar(title: Text(course.name)),
      body: ContentWidth(
        child: Padding(
          padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != null) ...[
              Text(description),
              const SizedBox(height: 16),
            ],
            Row(
              children: [
                Text(
                  'Topics',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _addTopic(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New topic'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildBody(BuildContext context, TopicsProvider provider) {
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(error: provider.error!);
    if (provider.topics.isEmpty) {
      return const EmptyState(
        message: 'No topics yet. Add one to organize this course.',
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
            onTap: () =>
                Navigator.of(context).push(FlashcardsScreen.route(topic)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editTopic(context, topic),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteTopic(context, topic),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
