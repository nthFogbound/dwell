import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/settings/settings_provider.dart';
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
    await provider.addFlashcard(
      front: result.front,
      back: result.back,
      tags: result.tags,
    );
  }

  Future<void> _editFlashcard(BuildContext context, Flashcard card) async {
    final provider = context.read<FlashcardsProvider>();
    final result = await showFlashcardFormDialog(context, flashcard: card);
    if (result == null) return;
    await provider.updateFlashcard(
      id: card.id,
      front: result.front,
      back: result.back,
      tags: result.tags,
    );
  }

  Future<void> _deleteFlashcard(BuildContext context, Flashcard card) async {
    final provider = context.read<FlashcardsProvider>();
    final language = context.read<SettingsProvider>().language;
    final confirmed = await showConfirmDeleteDialog(
      context,
      title: AppStrings.text('Delete flashcard?', language),
      message: AppStrings.text(
        'This flashcard will be permanently deleted.',
        language,
      ),
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
                  AppStrings.of(context, 'Flashcards'),
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
                  label: Text(AppStrings.of(context, 'Review')),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _addFlashcard(context),
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.of(context, 'New card')),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _StudyBanner(cards: provider.flashcards),
            const SizedBox(height: 16),
            _FilterBar(provider: provider),
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
    if (provider.filteredFlashcards.isEmpty) {
      final hasFilters =
          provider.searchQuery.isNotEmpty || provider.selectedTag != null;
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: EmptyState(
              message: provider.flashcards.isEmpty
                  ? AppStrings.of(
                      context,
                      'No flashcards yet. Add one to start studying.',
                    )
                  : AppStrings.of(
                      context,
                      'No flashcards match your current filters.',
                    ),
              icon: Icons.filter_alt_outlined,
            ),
          ),
          if (hasFilters)
            TextButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Icons.clear_all_outlined),
              label: Text(AppStrings.of(context, 'Clear filters')),
            ),
        ],
      );
    }

    return ListView.separated(
      itemCount: provider.filteredFlashcards.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final card = provider.filteredFlashcards[index];
        final tags = FlashcardRepository.parseTags(card.tags);
        return Card.filled(
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.style_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.front,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        card.back,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (tags.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final tag in tags)
                              Chip(
                                label: Text(tag),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    IconButton(
                      tooltip: AppStrings.of(context, 'Edit'),
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _editFlashcard(context, card),
                    ),
                    IconButton(
                      tooltip: AppStrings.of(context, 'Delete'),
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _deleteFlashcard(context, card),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StudyBanner extends StatelessWidget {
  const _StudyBanner({required this.cards});

  final List<Flashcard> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final taggedCount = cards
        .where((card) => FlashcardRepository.parseTags(card.tags).isNotEmpty)
        .length;
    final filipino =
        context.watch<SettingsProvider>().language == AppLanguage.filipino;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.surfaceContainerHighest,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: theme.colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context, 'Study cards'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.of(context, 'Tap a card to reveal its answer.'),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${cards.length}',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                filipino
                    ? 'card · $taggedCount naka-tag'
                    : 'cards · $taggedCount tagged',
                style: theme.textTheme.labelMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.provider});

  final FlashcardsProvider provider;

  @override
  Widget build(BuildContext context) {
    final tags = provider.availableTags;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search_outlined),
            hintText: AppStrings.of(context, 'Search card text or tags'),
            border: OutlineInputBorder(),
          ),
          onChanged: provider.setSearchQuery,
          controller: TextEditingController.fromValue(
            TextEditingValue(
              text: provider.searchQuery,
              selection: TextSelection.collapsed(
                offset: provider.searchQuery.length,
              ),
            ),
          ),
        ),
        if (tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: Text(AppStrings.of(context, 'All tags')),
                selected: provider.selectedTag == null,
                onSelected: (_) => provider.setSelectedTag(null),
              ),
              for (final tag in tags)
                FilterChip(
                  label: Text(tag),
                  selected: provider.selectedTag == tag,
                  onSelected: (_) => provider.setSelectedTag(
                    provider.selectedTag == tag ? null : tag,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
