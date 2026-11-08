import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import 'courses_provider.dart';
import 'widgets/course_form_dialog.dart';
import 'course_detail_screen.dart';

import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/status_views.dart';

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
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete course?',
      message:
          '"${course.name}" and all of its topics will be permanently deleted.',
    );
    if (!confirmed) return;
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
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(error: provider.error!);
    if (provider.courses.isEmpty) {
      return const EmptyState(
        message: 'No courses yet. Create one to get started.',
        icon: Icons.school_outlined,
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
