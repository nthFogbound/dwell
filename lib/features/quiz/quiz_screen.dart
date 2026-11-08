import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../data/repositories/quiz_repository.dart';
import 'quiz_provider.dart';

import '../../shared/widgets/status_views.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key, required this.courseId, this.topicId});

  final int courseId;
  final int? topicId;

  @override
  Widget build(BuildContext context) {
    // A fresh provider per quiz; disposed automatically when the screen closes.
    return ChangeNotifierProvider(
      create: (context) => QuizProvider(
        context.read<QuizRepository>(),
        courseId: courseId,
        topicId: topicId,
      )..start(),
      child: const _QuizView(),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Quiz')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: switch (quiz.status) {
              QuizStatus.loading => const LoadingView(),
              QuizStatus.notEnoughCards => const _NotEnoughCardsView(),
              QuizStatus.inProgress => const _QuestionView(),
              QuizStatus.finished => const _ResultView(),
            },
          ),
        ),
      ),
    );
  }
}

class _NotEnoughCardsView extends StatelessWidget {
  const _NotEnoughCardsView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'There aren\'t enough flashcards with different answers to build '
          'a quiz. Add more flashcards and try again.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
      ],
    );
  }
}

enum _OptionState { idle, correct, wrong }

class _QuestionView extends StatelessWidget {
  const _QuestionView();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final question = quiz.currentQuestion;
    final theme = Theme.of(context);

    _OptionState stateFor(int index) {
      if (!quiz.isAnswered) return _OptionState.idle;
      if (index == question.correctIndex) return _OptionState.correct;
      if (index == quiz.selectedIndex) return _OptionState.wrong;
      return _OptionState.idle;
    }

    // Bar fills as questions are answered, not just as they are reached.
    final answeredCount = quiz.currentNumber - 1 + (quiz.isAnswered ? 1 : 0);

    const digitKeys = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
    ];

    // CallbackShortcuts must be the PARENT of Focus (see review screen).
    return CallbackShortcuts(
      bindings: {
        for (var i = 0;
            i < question.options.length && i < digitKeys.length;
            i++)
          SingleActivator(digitKeys[i]): () {
            if (!quiz.isAnswered) {
              context.read<QuizProvider>().selectAnswer(i);
            }
          },
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (quiz.isAnswered) context.read<QuizProvider>().next();
        },
      },
      child: Focus(
        autofocus: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Question ${quiz.currentNumber} of ${quiz.totalQuestions}',
              style: theme.textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: answeredCount / quiz.totalQuestions),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(question.prompt, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 24),
                    for (var i = 0; i < question.options.length; i++)
                      _OptionTile(
                        number: i + 1,
                        text: question.options[i],
                        state: stateFor(i),
                        onTap: () =>
                            context.read<QuizProvider>().selectAnswer(i),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Press 1-${question.options.length} to answer  ·  '
                  'Enter for next',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: quiz.isAnswered
                      ? () => context.read<QuizProvider>().next()
                      : null,
                  child: Text(quiz.isLastQuestion ? 'Finish' : 'Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.number,
    required this.text,
    required this.state,
    required this.onTap,
  });
  
  final int number;
  final String text;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (
      Color background,
      Color foreground,
      IconData? icon,
    ) = switch (state) {
      _OptionState.idle => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        null,
      ),
      _OptionState.correct => (
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        Icons.check_circle,
      ),
      _OptionState.wrong => (
        scheme.errorContainer,
        scheme.onErrorContainer,
        Icons.cancel,
      ),
    };

    return Card.filled(
      color: background,
      clipBehavior: Clip.antiAlias, // keeps the click ripple inside the card
      child: ListTile(
        title: Text('$number.  $text', style: TextStyle(color: foreground)),
        // An icon, not just color, shows the result (helps color-blind users).
        trailing: icon == null ? null : Icon(icon, color: foreground),
        onTap: onTap,
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView();

  @override
  Widget build(BuildContext context) {
    final quiz = context.watch<QuizProvider>();
    final theme = Theme.of(context);
    final percent = (quiz.correctCount * 100 / quiz.totalQuestions).round();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Quiz complete', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 16),
        Text(
          '${quiz.correctCount} / ${quiz.totalQuestions}',
          style: theme.textTheme.displayMedium,
        ),
        Text('$percent% correct', style: theme.textTheme.titleMedium),
        const SizedBox(height: 32),
        Wrap(
          spacing: 12,
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
            FilledButton(
              // Replace this screen with a new quiz: fresh questions.
              onPressed: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => QuizScreen(
                    courseId: quiz.courseId,
                    topicId: quiz.topicId,
                  ),
                ),
              ),
              child: const Text('Try again'),
            ),
          ],
        ),
      ],
    );
  }
}
