import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_screen.dart';

class PortionApp extends StatelessWidget {
  const PortionApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Portion',
      theme: AppTheme.lightTheme,
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}