import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/settings/settings_provider.dart';
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
        create: (context) => ReviewProvider(
          context.read<FlashcardRepository>(),
          topic.id,
          repeatGap: context.read<SettingsProvider>().missedCardRepeatGap,
        ),
        child: ReviewScreen(topic: topic),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReviewProvider>();

    return PopScope<void>(
      canPop: provider.isEnded,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !provider.isEnded) provider.endSession();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(topic.name),
          leading: IconButton(
            tooltip: AppStrings.of(context, 'Back'),
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (provider.isEnded) {
                Navigator.of(context).pop();
              } else {
                provider.endSession();
              }
            },
          ),
        ),
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
      ),
    );
  }

  Widget _buildBody(BuildContext context, ReviewProvider provider) {
    if (provider.isLoading) return const LoadingView();
    if (provider.error != null) return ErrorView(error: provider.error!);
    if (provider.isComplete) {
      return _Summary(provider: provider);
    }
    if (provider.hasNothingDue) {
      return _NothingDueState(provider: provider);
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
    final progress = provider.total == 0
        ? 0.0
        : (provider.position / provider.total).clamp(0.0, 1.0);

    // Keyboard shortcuts for desktop: Enter/Space = reveal, 1/2 = missed/got it,
    // Left/Right = missed/got it. CallbackShortcuts must be the PARENT of Focus:
    // key events start at the focused widget and bubble upward.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): provider.reveal,
        const SingleActivator(LogicalKeyboardKey.space): provider.reveal,
        const SingleActivator(LogicalKeyboardKey.digit1): () {
          if (!revealed) {
            provider.reveal();
            return;
          }
          provider.answer(remembered: false);
        },
        const SingleActivator(LogicalKeyboardKey.numpad1): () {
          if (!revealed) {
            provider.reveal();
            return;
          }
          provider.answer(remembered: false);
        },
        const SingleActivator(LogicalKeyboardKey.digit2): () {
          if (!revealed) {
            provider.reveal();
            return;
          }
          provider.answer(remembered: true);
        },
        const SingleActivator(LogicalKeyboardKey.numpad2): () {
          if (!revealed) {
            provider.reveal();
            return;
          }
          provider.answer(remembered: true);
        },
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () =>
            provider.answer(remembered: false),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () =>
            provider.answer(remembered: true),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          unawaited(_undoResponse(context));
        },
        const SingleActivator(LogicalKeyboardKey.escape): provider.endSession,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              width: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppStrings.of(context, 'Cards reviewed'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${provider.position}/${provider.total}',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: TextButton.icon(
                      onPressed: provider.canUndo
                          ? () => _undoResponse(context)
                          : null,
                      icon: const Icon(Icons.undo),
                      label: Text(AppStrings.of(context, 'Undo')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: theme.colorScheme.surfaceContainerLow,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
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
            if (provider.currentCardIsRepeat) ...[
              const SizedBox(height: 4),
              Text(
                AppStrings.of(context, 'Reviewing again'),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '1 = ${AppStrings.of(context, 'Missed')}   2 = ${AppStrings.of(context, 'Got it')}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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

  Future<void> _undoResponse(BuildContext context) async {
    final undone = await provider.undoLastResponse();
    if (!undone || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context, 'Response undone'))),
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
    final accuracyPercent = (provider.accuracy * 100).round();
    final elapsed = provider.elapsed;
    final elapsedText = elapsed.inHours > 0
        ? '${elapsed.inHours}:${(elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}'
        : '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyR): provider.restart,
        const SingleActivator(LogicalKeyboardKey.keyD): () =>
            Navigator.of(context).popUntil((route) => route.isFirst),
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          unawaited(_undoFromSummary(context));
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
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
              AppStrings.of(context, 'Nice work — $accuracyPercent% accuracy!'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _SummaryStat(
              label: AppStrings.of(context, 'Unique cards reviewed'),
              value: '${provider.reviewedCount}',
            ),
            _SummaryStat(
              label: AppStrings.of(context, 'Total attempts'),
              value: '${provider.attempts}',
            ),
            _SummaryStat(
              label: AppStrings.of(context, 'Accuracy'),
              value: '$accuracyPercent%',
            ),
            _SummaryStat(
              label: AppStrings.of(context, 'Time spent'),
              value: elapsedText,
            ),
            _SummaryStat(
              label: AppStrings.of(context, 'Missed cards'),
              value: '${provider.missedCardsCount}',
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: provider.restart,
              icon: const Icon(Icons.restart_alt),
              label: Text(AppStrings.of(context, 'Study Again')),
              style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
            ),
            const SizedBox(height: 4),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
              child: Text(AppStrings.of(context, 'Done')),
            ),
            if (provider.canUndo)
              TextButton.icon(
                onPressed: () => _undoFromSummary(context),
                icon: const Icon(Icons.undo),
                label: Text(AppStrings.of(context, 'Undo last response')),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _undoFromSummary(BuildContext context) async {
    final undone = await provider.undoLastResponse();
    if (!undone || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.of(context, 'Response undone'))),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: '),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
}
