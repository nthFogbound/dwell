import 'package:flutter/material.dart';

import '../../../data/database/app_database.dart';

/// Returns the entered name, or null if cancelled.
/// [isNameTaken] lets the caller say whether a name is already used in this
/// course, so the dialog can show an error instead of closing.
Future<String?> showTopicFormDialog(
  BuildContext context, {
  Topic? topic,
  required Future<bool> Function(String name) isNameTaken,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _TopicFormDialog(topic: topic, isNameTaken: isNameTaken),
  );
}

class _TopicFormDialog extends StatefulWidget {
  const _TopicFormDialog({this.topic, required this.isNameTaken});

  final Topic? topic;
  final Future<bool> Function(String name) isNameTaken;

  @override
  State<_TopicFormDialog> createState() => _TopicFormDialogState();
}

class _TopicFormDialogState extends State<_TopicFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.topic?.name);

  String? _nameError; // set when the name is already taken
  bool _saving = false; // blocks double-clicks while the check runs

  @override
  void dispose() {
    _nameController.dispose();
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
        _nameError = 'This course already has a topic with this name';
      });
      return;
    }

    Navigator.of(context).pop(name);
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
            decoration: InputDecoration(
              labelText: 'Name',
              errorText: _nameError,
            ),
            onChanged: (_) {
              if (_nameError != null) setState(() => _nameError = null);
            },
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
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}