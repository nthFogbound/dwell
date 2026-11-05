import 'package:flutter/material.dart';
import '../../shared/widgets/placeholder_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const PlaceholderScreen(title: 'Progress', icon: Icons.insights_outlined);
}