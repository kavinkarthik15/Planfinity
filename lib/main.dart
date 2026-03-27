import 'package:flutter/material.dart';
import 'core/theme/theme.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const PlanfinityApp());
}

class PlanfinityApp extends StatelessWidget {
  const PlanfinityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planfinity',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
