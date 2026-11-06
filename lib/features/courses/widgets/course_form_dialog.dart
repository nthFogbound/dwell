import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// What the dialog returns when the user presses Save.
typedef CourseFormResult = ({String name, String? description});

Future<CourseFormResult?> showCourseFormDialog(
  BuildContext context, {
  Course? course,
}) {
  return showDialog<CourseFormResult>(
    context: context,
    builder: (_) => _CourseFormDialog(course: course),
  );
}

class _CourseFormDialog extends StatefulWidget {
  const _CourseFormDialog({this.course});

  final Course? course;

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController =
      TextEditingController(text: widget.course?.name);
  late final _descriptionController =
      TextEditingController(text: widget.course?.description);

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      description: _descriptionController.text,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.course != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit course' : 'New course'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                maxLength: 100,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a course name'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 1,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}