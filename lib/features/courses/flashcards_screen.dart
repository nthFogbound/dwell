import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';
import 'flashcards_provider.dart';
import 'widgets/flashcard_form_dialog.dart';
import 'review_screen.dart';

class FlashcardsScreen extends StatelessWidget {
  const FlashcardsScreen({super.key, required this.topic});

  final Topic topic;

  /// Opens this page with its own FlashcardsProvider for the given topic.
  static Route<void> route(Topic topic) {
    return MaterialPageRoute<void>(
      builder: (context) => ChangeNotifierProvider(
        create: (context) =>
            FlashcardsProvider(context.read<FlashcardRepository>(), topic.id),
        child: FlashcardsScreen(topic: topic),
      ),
    );
  }

  Future<void> _addFlashcard(BuildContext context) async {
    final provider = context.read<FlashcardsProvider>();
    final result = await showFlashcardFormDialog(context);
    if (result == null) return;
    await provider.addFlashcard(front: result.front, back: result.back);
  }

  Future<void> _editFlashcard(BuildContext context, Flashcard card) async {
    final provider = context.read<FlashcardsProvider>();
    final result = await showFlashcardFormDialog(context, flashcard: card);
    if (result == null) return;
    await provider.updateFlashcard(
      id: card.id,
      front: result.front,
      back: result.back,
    );
  }

  Future<void> _deleteFlashcard(BuildContext context, Flashcard card) async {
    final provider = context.read<FlashcardsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete flashcard?'),
        content: const Text('This flashcard will be permanently deleted.'),
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
    await provider.deleteFlashcard(card.id);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FlashcardsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(topic.name)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Flashcards',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: provider.flashcards.isEmpty
                      ? null
                      : () => Navigator.of(context)
                          .push(ReviewScreen.route(topic)),
                  icon: const Icon(Icons.style_outlined),
                  label: const Text('Review'),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => _addFlashcard(context),
                  icon: const Icon(Icons.add),
                  label: const Text('New card'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody(context, provider)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, FlashcardsProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.error != null) {
      return Center(child: Text('Something went wrong: ${provider.error}'));
    }
    if (provider.flashcards.isEmpty) {
      return const Center(
        child: Text('No flashcards yet. Add one to start studying.'),
      );
    }

    return ListView.separated(
      itemCount: provider.flashcards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final card = provider.flashcards[index];
        return Card(
          margin: EdgeInsets.zero,
          child: ListTile(
            title: Text(card.front, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text(card.back, maxLines: 2, overflow: TextOverflow.ellipsis),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _editFlashcard(context, card),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _deleteFlashcard(context, card),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}