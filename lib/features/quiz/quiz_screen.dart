import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/repositories/quiz_repository.dart';
import 'quiz_provider.dart';

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
      body: Center(child: Text('Status: ${quiz.status.name}')), // placeholder
    );
  }
}