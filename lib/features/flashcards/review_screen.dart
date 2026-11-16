import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/flashcard_repository.dart';
import 'review_provider.dart';

import '../../shared/widgets/status_views.dart';

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
      appBar: AppBar(title: Text(topic.name)),
      body: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: _buildBody(context, provider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReviewProvider provider) {
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(error: provider.error!);
    if (provider.hasNothingDue) {
      return _NothingDueState(provider: provider);
    }
    if (provider.isComplete) {
      return _Summary(provider: provider);
    }
    return _CardView(provider: provider);
  }
}

class _NothingDueState extends StatelessWidget {
  const _NothingDueState({required this.provider});

  final ReviewProvider provider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.of(context, 'Nothing due right now. Check back later.'),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: provider.reviewAllCards,
            icon: const Icon(Icons.replay),
            label: Text(AppStrings.of(context, 'Review all cards')),
          ),
        ],
      ),
    );
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
    // Right = got it. CallbackShortcuts must be the PARENT of Focus: key
    // events start at the focused widget and bubble upward.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): provider.reveal,
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            provider.answer(remembered: false),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            provider.answer(remembered: true),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 470),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Card(
                      margin: EdgeInsets.zero,
                      color: theme.colorScheme.surfaceContainerHighest,
                      clipBehavior: Clip.antiAlias,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: InkWell(
                        onTap: revealed ? null : provider.reveal,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${provider.position + 1}/${provider.total}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: SingleChildScrollView(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        child: Text(
                                          revealed ? card.back : card.front,
                                          key: ValueKey(revealed),
                                          style: theme.textTheme.headlineSmall
                                              ?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                height: 1.35,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (!revealed)
                                Text(
                                  AppStrings.of(context, 'See answer'),
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _RatingButton(
                  count: provider.missedCount,
                  icon: Icons.close,
                  color: theme.colorScheme.error,
                  tooltip: AppStrings.of(context, 'Missed'),
                  onPressed: revealed
                      ? () => provider.answer(remembered: false)
                      : null,
                ),
                const SizedBox(width: 16),
                _RatingButton(
                  count: provider.rememberedCount,
                  icon: Icons.check,
                  color: Colors.green,
                  tooltip: AppStrings.of(context, 'Got it'),
                  onPressed: revealed
                      ? () => provider.answer(remembered: true)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _RatingButton extends StatelessWidget {
  const _RatingButton({
    required this.count,
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onPressed,
  });

  final int count;
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: onPressed == null ? null : color),
        label: Text('$count'),
        style: OutlinedButton.styleFrom(
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
        Icon(
          Icons.celebration_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          AppStrings.of(context, 'Session complete'),
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.of(
            context,
            '${provider.rememberedCount} remembered · ${provider.missedCount} missed',
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: provider.restart,
          icon: const Icon(Icons.restart_alt),
          label: Text(AppStrings.of(context, 'Restart')),
          style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(AppStrings.of(context, 'Done')),
        ),
      ],
    );
  }
}
