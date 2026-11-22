import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../../core/localization/app_strings.dart';
import '../../../core/settings/settings_provider.dart';
import '../../../data/repositories/flashcard_repository.dart';
import '../../../data/repositories/topic_repository.dart';

Future<void> showQuickAddDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (_) => const _QuickAddDialog(),
  );
}

class _QuickAddDialog extends StatefulWidget {
  const _QuickAddDialog();

  @override
  State<_QuickAddDialog> createState() => _QuickAddDialogState();
}

class _QuickAddDialogState extends State<_QuickAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _frontController = TextEditingController();
  final _backController = TextEditingController();
  List<TopicWithCourse> _topics = [];
  int? _selectedTopicId;
  bool _isLoading = true;
  bool _isSaving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadTopics();
  }

  Future<void> _loadTopics() async {
    try {
      final topics = await context
          .read<TopicRepository>()
          .getTopicsWithCourses();
      if (!mounted) return;
      final lastTopicId = context.read<SettingsProvider>().lastTopicId;
      setState(() {
        _topics = topics;
        _selectedTopicId = topics.any((entry) => entry.topic.id == lastTopicId)
            ? lastTopicId
            : topics.isEmpty
            ? null
            : topics.first.topic.id;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _save({required bool addAnother}) async {
    if (_isSaving || _formKey.currentState?.validate() != true) return;
    final topicId = _selectedTopicId;
    if (topicId == null) return;
    final repository = context.read<FlashcardRepository>();
    final settings = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final focusScope = FocusScope.of(context);
    final preferenceFailureMessage = AppStrings.text(
      'Card saved, but the last-used topic could not be saved:',
      settings.language,
    );

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await repository.addFlashcard(
        topicId: topicId,
        front: _frontController.text,
        back: _backController.text,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error;
          _isSaving = false;
        });
      }
      return;
    }

    Object? preferenceError;
    try {
      await settings.setLastTopicId(topicId);
    } catch (error) {
      preferenceError = error;
    }
    if (!mounted) return;
    if (preferenceError != null) {
      messenger.showSnackBar(
        SnackBar(content: Text('$preferenceFailureMessage $preferenceError')),
      );
    }
    if (addAnother) {
      _frontController.clear();
      _backController.clear();
      setState(() => _isSaving = false);
      focusScope.requestFocus(_frontFocusNode);
    } else {
      navigator.pop();
    }
  }

  final FocusNode _frontFocusNode = FocusNode();

  @override
  void dispose() {
    _frontController.dispose();
    _backController.dispose();
    _frontFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String strings(String value) => AppStrings.of(context, value);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(
          LogicalKeyboardKey.keyN,
          control: true,
          shift: true,
        ): () {},
        const SingleActivator(LogicalKeyboardKey.enter, control: true): () {
          _save(addAnother: false);
        },
        const SingleActivator(
          LogicalKeyboardKey.enter,
          control: true,
          shift: true,
        ): () {
          _save(addAnother: true);
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!_isSaving) Navigator.of(context).pop();
        },
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: Text(strings('Quick add')),
          content: SizedBox(
            width: 440,
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : _error != null && _topics.isEmpty
                ? Text(
                    '${strings('Topics could not be loaded:')} $_error',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  )
                : _topics.isEmpty
                ? Text(
                    strings('Create a course and add topics to get started.'),
                  )
                : Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _selectedTopicId,
                          decoration: InputDecoration(
                            labelText: strings('Course / topic'),
                          ),
                          items: [
                            for (final entry in _topics)
                              DropdownMenuItem(
                                value: entry.topic.id,
                                child: Text(
                                  '${entry.courseName} · ${entry.topic.name}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: _isSaving
                              ? null
                              : (value) =>
                                    setState(() => _selectedTopicId = value),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _frontController,
                          focusNode: _frontFocusNode,
                          autofocus: true,
                          maxLength: 1000,
                          decoration: InputDecoration(
                            labelText: strings('Front (question)'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? strings('Required')
                              : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _backController,
                          maxLength: 2000,
                          minLines: 1,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: strings('Back (answer)'),
                            border: const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? strings('Required')
                              : null,
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${strings('Something went wrong:')} $_error',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
          ),
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
              child: Text(strings('Cancel')),
            ),
            OutlinedButton(
              onPressed: _isLoading || _isSaving || _topics.isEmpty
                  ? null
                  : () => _save(addAnother: true),
              child: Text(strings('Save & Add Another')),
            ),
            FilledButton(
              onPressed: _isLoading || _isSaving || _topics.isEmpty
                  ? null
                  : () => _save(addAnother: false),
              child: Text(strings('Save & Close')),
            ),
          ],
        ),
      ),
    );
  }
}
