import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import 'courses_provider.dart';
import 'widgets/course_form_dialog.dart';
import 'course_detail_screen.dart';

class CoursesScreen extends StatelessWidget {
  const CoursesScreen({super.key});

  Future<void> _addCourse(BuildContext context) async {
    final provider = context.read<CoursesProvider>();
    final result = await showCourseFormDialog(context);
    if (result == null) return; // Cancelled.
    await provider.addCourse(
      name: result.name,
      description: result.description,
    );
  }

  Future<void> _editCourse(BuildContext context, Course course) async {
    final provider = context.read<CoursesProvider>();
    final result = await showCourseFormDialog(context, course: course);
    if (result == null) return;
    await provider.updateCourse(
      id: course.id,
      name: result.name,
      description: result.description,
    );
  }

  Future<void> _deleteCourse(BuildContext context, Course course) async {
    final provider = context.read<CoursesProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete course?'),
        content: Text(
          '"${course.name}" and all of its topics will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await provider.deleteCourse(course.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CoursesProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Courses',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _addCourse(context),
                icon: const Icon(Icons.add),
                label: const Text('New course'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(context, provider)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, CoursesProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Something went wrong: ${provider.error}'));
    }
    if (provider.courses.isEmpty) {
      return const Center(
        child: Text('No courses yet. Create one to get started.'),
      );
    }

    return ListView.separated(
      itemCount: provider.courses.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final course = provider.courses[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            onTap: () =>
                Navigator.of(context).push(CourseDetailScreen.route(course)),
            title: Text(course.name),
            subtitle: course.description == null
                ? null
                : Text(course.description!),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editCourse(context, course),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteCourse(context, course),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
