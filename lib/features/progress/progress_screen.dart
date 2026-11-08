import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/progress_repository.dart';
import 'progress_provider.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: _buildBody(context, progress),
    );
  }

  Widget _buildBody(BuildContext context, ProgressProvider progress) {
    if (progress.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (progress.error != null) {
      return const Center(child: Text('Could not load progress.'));
    }

    final theme = Theme.of(context);

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            _SummaryCard(progress: progress),
            const SizedBox(height: 32),
            Text('Courses', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (progress.courseProgress.isEmpty)
              const Text('No courses yet.')
            else
              for (final item in progress.courseProgress)
                _CourseProgressCard(progress: item),
            const SizedBox(height: 32),
            Text('Recent quizzes', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (progress.history.isEmpty)
              const Text('No quizzes taken yet.')
            else
              for (final entry in progress.history)
                _QuizHistoryCard(entry: entry),
          ],
        ),
      ),
    );
  }
}

String _percent(double fraction) => '${(fraction * 100).round()}%';

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.progress});

  final ProgressProvider progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accuracy = progress.recentAccuracy;

    return Card.filled(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overall mastery', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(
              '${progress.masteredCards} of ${progress.totalCards} '
              'cards mastered',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: progress.overallMasteredFraction),
            const SizedBox(height: 8),
            Text(
              'Cards in box ${ProgressRepository.masteredBox} or higher '
              'count as mastered.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              accuracy == null
                  ? 'No quizzes taken yet.'
                  : 'Recent quiz accuracy: ${_percent(accuracy)} '
                      '(last ${progress.history.length} quizzes)',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseProgressCard extends StatelessWidget {
  const _CourseProgressCard({required this.progress});

  final CourseProgress progress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    progress.course.name,
                    style: theme.textTheme.titleSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  progress.totalCards == 0
                      ? 'No cards'
                      : '${progress.masteredCards} / ${progress.totalCards} '
                          'mastered',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progress.masteredFraction),
          ],
        ),
      ),
    );
  }
}

class _QuizHistoryCard extends StatelessWidget {
  const _QuizHistoryCard({required this.entry});

  final QuizHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Built-in date/time formatting, so no extra package is needed.
    final localizations = MaterialLocalizations.of(context);
    final taken = entry.takenAt.toLocal();
    final when = '${localizations.formatMediumDate(taken)} · '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(taken))}';

    final title = entry.topicName == null
        ? entry.courseName
        : '${entry.courseName} · ${entry.topicName}';

    return Card.outlined(
      child: ListTile(
        title: Text(title, overflow: TextOverflow.ellipsis),
        subtitle: Text(when),
        trailing: Text(
          '${entry.correctAnswers}/${entry.totalQuestions} · '
          '${_percent(entry.scoreFraction)}',
          style: theme.textTheme.titleSmall,
        ),
      ),
    );
  }
}