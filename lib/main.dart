import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Bug fix: separate try-catch so a timeout on initialize() doesn't skip scheduling.
  try {
    await NotificationService.initialize()
        .timeout(const Duration(seconds: 5));
  } catch (e, stack) {
    debugPrint('NOTIFICATION ERROR during initialize: $e\n$stack');
  }
  // Request permissions at startup — not just when the user toggles the switch.
  // Without this, a fresh install (notifications enabled by default) never asks for
  // SCHEDULE_EXACT_ALARM and silently falls back to inexact alarms.
  try {
    await NotificationService.requestPermissions()
        .timeout(const Duration(seconds: 5));
  } catch (e, stack) {
    debugPrint('NOTIFICATION ERROR during requestPermissions: $e\n$stack');
  }
  try {
    await NotificationService.scheduleFromPrefs()
        .timeout(const Duration(seconds: 5));
  } catch (e, stack) {
    debugPrint('NOTIFICATION ERROR during scheduleFromPrefs: $e\n$stack');
  }

  runApp(
    const ProviderScope(
      child: FinanceFlowApp(),
    ),
  );
}

class FinanceFlowApp extends StatelessWidget {
  const FinanceFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Flow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
