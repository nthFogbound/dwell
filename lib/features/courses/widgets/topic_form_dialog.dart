import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// Returns the entered name, or null if cancelled.
Future<String?> showTopicFormDialog(BuildContext context, {Topic? topic}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TopicFormDialog(topic: topic),
  );
}

class _TopicFormDialog extends StatefulWidget {
  const _TopicFormDialog({this.topic});

  final Topic? topic;

  @override
  State<_TopicFormDialog> createState() => _TopicFormDialogState();
}

class _TopicFormDialogState extends State<_TopicFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.topic?.name);

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(_nameController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.topic == null ? 'New topic' : 'Edit topic'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: TextFormField(
            controller: _nameController,
            autofocus: true,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'Name'),
            onFieldSubmitted: (_) => _submit(), // Enter key saves.
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Enter a topic name'
                : null,
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
