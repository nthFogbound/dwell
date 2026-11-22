import 'package:material_ui/material_ui.dart';

import '../../../core/localization/app_strings.dart';
import '../../../data/database/app_database.dart';

/// What the dialog returns when the user saves.
typedef FlashcardFormResult = ({String front, String back, String tags});

/// Opens the create/edit dialog. Pass [flashcard] to edit; omit it to create.
/// Returns null if the user cancels.
Future<FlashcardFormResult?> showFlashcardFormDialog(
  BuildContext context, {
  Flashcard? flashcard,
}) {
  return showDialog<FlashcardFormResult>(
    context: context,
    builder: (_) => _FlashcardFormDialog(flashcard: flashcard),
  );
}

class _FlashcardFormDialog extends StatefulWidget {
  const _FlashcardFormDialog({this.flashcard});

  final Flashcard? flashcard;

  @override
  State<_FlashcardFormDialog> createState() => _FlashcardFormDialogState();
}

class _FlashcardFormDialogState extends State<_FlashcardFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _front;
  late final TextEditingController _back;
  late final TextEditingController _tags;

  @override
  void initState() {
    super.initState();
    _front = TextEditingController(text: widget.flashcard?.front);
    _back = TextEditingController(text: widget.flashcard?.back);
    _tags = TextEditingController(text: widget.flashcard?.tags ?? '');
  }

  @override
  void dispose() {
    _front.dispose();
    _back.dispose();
    _tags.dispose();
    super.dispose();
  }

  String? _required(String? value) => (value == null || value.trim().isEmpty)
      ? AppStrings.of(context, 'Required')
      : null;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      front: _front.text.trim(),
      back: _back.text.trim(),
      tags: _tags.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.flashcard != null;

    return AlertDialog(
      title: Text(
        AppStrings.of(context, isEditing ? 'Edit flashcard' : 'New flashcard'),
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _front,
                autofocus: true,
                minLines: 2,
                maxLines: 6,
                maxLength: 1000, // matches the table's column limit
                decoration: InputDecoration(
                  labelText: AppStrings.of(context, 'Front (question)'),
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _back,
                minLines: 2,
                maxLines: 6,
                maxLength: 2000, // matches the table's column limit
                decoration: InputDecoration(
                  labelText: AppStrings.of(context, 'Back (answer)'),
                  border: OutlineInputBorder(),
                ),
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _tags,
                maxLength: 300,
                decoration: InputDecoration(
                  labelText: AppStrings.of(context, 'Tags (optional)'),
                  hintText: 'biology, exam, chapter 2',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.of(context, 'Cancel')),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(AppStrings.of(context, isEditing ? 'Save' : 'Add')),
        ),
      ],
    );
  }
}
