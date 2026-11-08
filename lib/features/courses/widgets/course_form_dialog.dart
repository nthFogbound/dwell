import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// What the dialog returns when the user presses Save.
typedef CourseFormResult = ({String name, String? description});

/// [isNameTaken] lets the caller (via its provider) say whether a name is
/// already used, so the dialog can show an error instead of closing.
Future<CourseFormResult?> showCourseFormDialog(
  BuildContext context, {
  Course? course,
  required Future<bool> Function(String name) isNameTaken,
}) {
  return showDialog<CourseFormResult>(
    context: context,
    builder: (_) =>
        _CourseFormDialog(course: course, isNameTaken: isNameTaken),
  );
}

class _CourseFormDialog extends StatefulWidget {
  const _CourseFormDialog({this.course, required this.isNameTaken});

  final Course? course;
  final Future<bool> Function(String name) isNameTaken;

  @override
  State<_CourseFormDialog> createState() => _CourseFormDialogState();
}

class _CourseFormDialogState extends State<_CourseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.course?.name);
  late final _descriptionController = TextEditingController(
    text: widget.course?.description,
  );

  String? _nameError; // set when the name is already taken
  bool _saving = false; // blocks double-clicks while the check runs

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    setState(() => _saving = true);
    final taken = await widget.isNameTaken(name);
    if (!mounted) return;

    if (taken) {
      setState(() {
        _saving = false;
        _nameError = 'A course with this name already exists';
      });
      return;
    }

    Navigator.of(context).pop((
      name: name,
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
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: _nameError,
                ),
                onChanged: (_) {
                  if (_nameError != null) setState(() => _nameError = null);
                },
                onFieldSubmitted: (_) => _submit(), // Enter key saves.
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Enter a course name'
                    : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                minLines: 1,
                maxLines: 3,
                maxLength: 500,
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
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}