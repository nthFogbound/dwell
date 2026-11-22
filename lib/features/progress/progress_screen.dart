import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' hide Column;
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_strings.dart';
import '../../core/settings/settings_provider.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/progress_repository.dart';
import '../../shared/widgets/status_views.dart';
import 'progress_provider.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _dailyGoal = 20;
  bool _loadingGoal = true;

  @override
  void initState() {
    super.initState();
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final goal = await _DailyGoalStore().getDailyGoal();
    if (!mounted) return;
    setState(() {
      _dailyGoal = goal;
      _loadingGoal = false;
    });
  }

  Future<void> _saveGoal(int goal) async {
    final safeGoal = goal.clamp(5, 100);
    await _DailyGoalStore().setDailyGoal(safeGoal);
    if (!mounted) return;
    setState(() => _dailyGoal = safeGoal);
  }

  Future<void> _exportBackup() async {
    final db = context.read<AppDatabase>();
    final language = context.read<SettingsProvider>().language;
    try {
      final filePath = await _BackupService(db).exportData();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppStrings.text('Backup exported to', language)} $filePath',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.text('Something went wrong: $error', language),
          ),
        ),
      );
    }
  }

  Future<void> _restoreLatestBackup() async {
    final db = context.read<AppDatabase>();
    final language = context.read<SettingsProvider>().language;
    try {
      final restored = await _BackupService(db).restoreLatest();
      if (!mounted) return;
      final message = restored
          ? AppStrings.text('Latest backup restored.', language)
          : AppStrings.text(
              'No backup file was found in your Documents folder.',
              language,
            );
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.text('Something went wrong: $error', language),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = context.watch<ProgressProvider>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppStrings.of(context, 'Progress'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),
          Expanded(child: _buildBody(context, progress)),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, ProgressProvider progress) {
    if (progress.isLoading || _loadingGoal) return const LoadingView();
    if (progress.error != null) return ErrorView(error: progress.error!);

    final theme = Theme.of(context);
    final summary = progress.dailySummary;

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        _SummaryCard(progress: progress),
        const SizedBox(height: 16),
        _DailyGoalCard(
          progress: progress,
          dailyGoal: _dailyGoal,
          onChanged: _saveGoal,
        ),
        const SizedBox(height: 16),
        Card.outlined(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.of(context, 'Study analytics'),
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.of(context, 'Reviewed today'),
                        value: '${summary.reviewsToday}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        label: AppStrings.of(context, 'Due today'),
                        value: '${summary.cardsDueToday}',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  AppStrings.of(
                    context,
                    'Overdue cards: ${summary.cardsOverdue} · '
                    'Goal progress: ${summary.reviewsToday} / $_dailyGoal',
                  ),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _exportBackup,
                icon: const Icon(Icons.download_outlined),
                label: Text(AppStrings.of(context, 'Export backup')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _restoreLatestBackup,
                icon: const Icon(Icons.restore_outlined),
                label: Text(AppStrings.of(context, 'Restore backup')),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text(
          AppStrings.of(context, 'Courses'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (progress.courseProgress.isEmpty)
          Text(AppStrings.of(context, 'No courses yet.'))
        else
          for (final item in progress.courseProgress)
            _CourseProgressCard(progress: item),
        const SizedBox(height: 32),
        Text(
          AppStrings.of(context, 'Recent quizzes'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (progress.history.isEmpty)
          Text(AppStrings.of(context, 'No quizzes taken yet.'))
        else
          for (final entry in progress.history) _QuizHistoryCard(entry: entry),
      ],
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
            Text(
              AppStrings.of(context, 'Overall mastery'),
              style: theme.textTheme.titleMedium,
            ),
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
              AppStrings.of(
                context,
                'Cards in box ${ProgressRepository.masteredBox} or higher '
                'count as mastered.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              accuracy == null
                  ? AppStrings.of(context, 'No quizzes taken yet.')
                  : AppStrings.of(
                      context,
                      'Recent quiz accuracy: ${_percent(accuracy)} '
                      '(last ${progress.history.length} quizzes)',
                    ),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({
    required this.progress,
    required this.dailyGoal,
    required this.onChanged,
  });

  final ProgressProvider progress;
  final int dailyGoal;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = progress.dailySummary.reviewsToday;
    final value = (completed / dailyGoal).clamp(0.0, 1.0);

    return Card.outlined(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.of(context, 'Daily goal'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.of(
                context,
                '$completed / $dailyGoal cards reviewed today',
              ),
              style: theme.textTheme.titleSmall,
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(value: value.isFinite ? value : 0),
            const SizedBox(height: 12),
            Text(
              AppStrings.of(
                context,
                'Adjust your daily target to keep momentum.',
              ),
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Slider(
              value: dailyGoal.toDouble(),
              min: 5,
              max: 100,
              divisions: 19,
              label: AppStrings.of(context, '$dailyGoal cards'),
              onChanged: (value) => onChanged(value.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 4),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
        ],
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
                      ? AppStrings.of(context, 'No cards')
                      : AppStrings.of(
                          context,
                          '${progress.masteredCards} / ${progress.totalCards} '
                          'mastered',
                        ),
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

    final localizations = MaterialLocalizations.of(context);
    final taken = entry.takenAt.toLocal();
    final when =
        '${localizations.formatMediumDate(taken)} · '
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

class _DailyGoalStore {
  Future<String> _path() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}${Platform.pathSeparator}dwell_settings.json';
  }

  Future<int> getDailyGoal() async {
    final file = File(await _path());
    if (!file.existsSync()) return 20;
    try {
      final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final goal = data['dailyGoal'];
      if (goal is int) return goal.clamp(5, 100);
      if (goal is String) return int.tryParse(goal)?.clamp(5, 100) ?? 20;
    } catch (_) {}
    return 20;
  }

  Future<void> setDailyGoal(int goal) async {
    final file = File(await _path());
    final payload = {'dailyGoal': goal.clamp(5, 100)};
    await file.parent.create(recursive: true);
    await file.writeAsString(jsonEncode(payload));
  }
}

class _BackupService {
  _BackupService(this._db);

  final AppDatabase _db;

  Future<Directory> _backupDirectory() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docsDir.path}${Platform.pathSeparator}dwell_backups');
    await dir.create(recursive: true);
    return dir;
  }

  Future<String> exportData() async {
    final courses = await _db.select(_db.courses).get();
    final topics = await _db.select(_db.topics).get();
    final flashcards = await _db.select(_db.flashcards).get();
    final attempts = await _db.select(_db.quizAttempts).get();

    final dir = await _backupDirectory();
    final stamp = DateTime.now().toUtc().toIso8601String().replaceAll(':', '-');
    final file = File('${dir.path}${Platform.pathSeparator}dwell_backup_$stamp.json');
    await file.writeAsString(
      jsonEncode({
        'version': 1,
        'exportedAt': DateTime.now().toUtc().toIso8601String(),
        'courses': courses
            .map(
              (course) => {
                'id': course.id,
                'name': course.name,
                'description': course.description,
                'createdAt': course.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'topics': topics
            .map(
              (topic) => {
                'id': topic.id,
                'courseId': topic.courseId,
                'name': topic.name,
                'createdAt': topic.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'flashcards': flashcards
            .map(
              (card) => {
                'id': card.id,
                'topicId': card.topicId,
                'front': card.front,
                'back': card.back,
                'tags': card.tags,
                'box': card.box,
                'dueAt': card.dueAt.toIso8601String(),
                'lastReviewedAt': card.lastReviewedAt?.toIso8601String(),
                'createdAt': card.createdAt.toIso8601String(),
              },
            )
            .toList(),
        'quizAttempts': attempts
            .map(
              (attempt) => {
                'id': attempt.id,
                'courseId': attempt.courseId,
                'topicId': attempt.topicId,
                'totalQuestions': attempt.totalQuestions,
                'correctAnswers': attempt.correctAnswers,
                'takenAt': attempt.takenAt.toIso8601String(),
              },
            )
            .toList(),
      }),
    );
    return file.path;
  }

  Future<bool> restoreLatest() async {
    final rootDir = await getApplicationDocumentsDirectory();
    final backupDir = await _backupDirectory();
    final directories = [rootDir, backupDir];
    final candidates = <File>[];

    for (final directory in directories) {
      if (!directory.existsSync()) continue;
      candidates.addAll(
        directory
            .listSync()
            .whereType<File>()
            .where((file) => file.path.contains('dwell_backup_'))
            .toList(),
      );
    }

    if (candidates.isEmpty) return false;

    candidates.sort(
      (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
    );
    final newest = candidates.first;
    final payload = jsonDecode(await newest.readAsString());
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Backup file is not valid JSON data.');
    }

    final data = payload;

    await _db.transaction(() async {
      await (_db.delete(_db.quizAttempts)).go();
      await (_db.delete(_db.flashcards)).go();
      await (_db.delete(_db.topics)).go();
      await (_db.delete(_db.courses)).go();

      final courseMap = <int, int>{};
      for (final item in (data['courses'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final id = await _db
            .into(_db.courses)
            .insert(
              CoursesCompanion.insert(
                name: row['name'] as String,
                description: Value(row['description'] as String?),
                createdAt: Value(DateTime.parse(row['createdAt'] as String)),
              ),
            );
        courseMap[row['id'] as int] = id;
      }

      final topicMap = <int, int>{};
      for (final item in (data['topics'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final courseId = courseMap[row['courseId'] as int];
        if (courseId == null) continue;
        final id = await _db
            .into(_db.topics)
            .insert(
              TopicsCompanion.insert(
                courseId: courseId,
                name: row['name'] as String,
                createdAt: Value(DateTime.parse(row['createdAt'] as String)),
              ),
            );
        topicMap[row['id'] as int] = id;
      }

      for (final item in (data['flashcards'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final topicId = topicMap[row['topicId'] as int];
        if (topicId == null) continue;
        await _db
            .into(_db.flashcards)
            .insert(
              FlashcardsCompanion.insert(
                topicId: topicId,
                front: row['front'] as String,
                back: row['back'] as String,
                tags: Value((row['tags'] as String?) ?? ''),
                box: Value((row['box'] as int?) ?? 1),
                dueAt: Value(DateTime.parse(row['dueAt'] as String)),
                lastReviewedAt: Value(
                  row['lastReviewedAt'] == null
                      ? null
                      : DateTime.parse(row['lastReviewedAt'] as String),
                ),
                createdAt: Value(DateTime.parse(row['createdAt'] as String)),
              ),
            );
      }

      for (final item in (data['quizAttempts'] as List? ?? const [])) {
        final row = item as Map<String, dynamic>;
        final courseId = courseMap[row['courseId'] as int];
        final topicId = row['topicId'] == null
            ? null
            : topicMap[row['topicId'] as int];
        if (courseId == null) continue;
        await _db
            .into(_db.quizAttempts)
            .insert(
              QuizAttemptsCompanion.insert(
                courseId: courseId,
                topicId: Value(topicId),
                totalQuestions: row['totalQuestions'] as int,
                correctAnswers: row['correctAnswers'] as int,
                takenAt: Value(DateTime.parse(row['takenAt'] as String)),
              ),
            );
      }
    });

    return true;
  }
}
