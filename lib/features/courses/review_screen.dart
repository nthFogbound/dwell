import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';
import 'review_provider.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key, required this.topic});

  final Topic topic;

  /// Opens this page with its own ReviewProvider for the given topic.
  static Route<void> route(Topic topic) {
    return MaterialPageRoute<void>(
      builder: (context) => ChangeNotifierProvider(
        create: (context) =>
            ReviewProvider(context.read<FlashcardRepository>(), topic.id),
        child: ReviewScreen(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Review: ${topic.name}')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: _buildBody(context, provider),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReviewProvider provider) {
    if (provider.isLoading) {
      return const CircularProgressIndicator();
    }
    if (provider.error != null) {
      return Text('Something went wrong: ${provider.error}');
    }
    if (provider.hasNothingDue) {
      return const _Message(
        icon: Icons.check_circle_outline,
        text: 'Nothing due right now. Check back later.',
      );
    }
    if (provider.isComplete) {
      return _Summary(provider: provider);
    }
    return _CardView(provider: provider);
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.provider});

  final ReviewProvider provider;

  @override
  Widget build(BuildContext context) {
    final card = provider.currentCard!;
    final revealed = provider.isRevealed;
    final theme = Theme.of(context);

    // Keyboard shortcuts for desktop: Space = show answer, Left = missed,
    // Right = got it.
    return Focus(
      autofocus: true,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.space): provider.reveal,
          const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
              provider.answer(remembered: false),
          const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
              provider.answer(remembered: true),
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Card ${provider.position + 1} of ${provider.total}',
              style: theme.textTheme.labelLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: provider.position / provider.total),
            const SizedBox(height: 24),
            Card(
              margin: EdgeInsets.zero,
              child: InkWell(
                onTap: provider.reveal,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 280,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          revealed ? 'ANSWER' : 'QUESTION',
                          style: theme.textTheme.labelSmall,
                        ),
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              child: Text(
                                revealed ? card.back : card.front,
                                style: theme.textTheme.headlineSmall,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (!revealed)
              FilledButton(
                onPressed: provider.reveal,
                child: const Text('Show answer'),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => provider.answer(remembered: false),
                      child: const Text('Missed'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => provider.answer(remembered: true),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.provider});

  final ReviewProvider provider;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.celebration_outlined,
            size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text('Session complete',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          '${provider.rememberedCount} remembered · '
          '${provider.missedCount} missed',
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Done'),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 16),
        Text(text),
      ],
    );
  }
}