import 'package:flutter/material.dart';
import '../../shared/widgets/placeholder_screen.dart';

class QuizScreen extends StatelessWidget {
  const QuizScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Quiz', icon: Icons.quiz_outlined);
}