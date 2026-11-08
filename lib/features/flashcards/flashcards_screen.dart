import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';
import 'flashcards_provider.dart';
import 'widgets/flashcard_form_dialog.dart';
import 'review_screen.dart';

import '../../shared/widgets/confirm_delete_dialog.dart';
import '../../shared/widgets/status_views.dart';

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
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: 'Delete flashcard?',
      message: 'This flashcard will be permanently deleted.',
    );
    if (!confirmed) return;
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
                      : () =>
                            Navigator.of(context)
                                .push(ReviewScreen.route(topic)),
                  icon: const Icon(Icons.style_outlined),
                  label: const Text('Review'),
                ),
                const SizedBox(width: 8),
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
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(error: provider.error!);
    if (provider.flashcards.isEmpty) {
      return const EmptyState(
        message: 'No flashcards yet. Add one to start studying.',
        icon: Icons.style_outlined,
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
            title: Text(
              card.front,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              card.back,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
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
