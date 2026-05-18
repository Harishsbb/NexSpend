import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import '../services/bio_auth_service.dart';
import '../services/notification_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
    _navigateToHome();
  }

  Future<void> _initNotifications() async {
    await NotificationService.requestPermissions();
    final prefs = await SharedPreferences.getInstance();
    final hasShownWelcome = prefs.getBool('has_shown_welcome_notif') ?? false;
    if (!hasShownWelcome && !kIsWeb) {
      // Delay slightly to give time for permission acceptance and smooth rendering
      await Future.delayed(const Duration(seconds: 4));
      await NotificationService.showTestNotification();
      await prefs.setBool('has_shown_welcome_notif', true);
    }
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    User? user;
    try {
      user = await ref.read(authServiceProvider).authStateChanges.first.timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      user = null;
    }

    if (!mounted) return;

    if (user != null) {
      final bioAuth = ref.read(bioAuthServiceProvider);
      try {
        final isAvailable = await bioAuth.isBiometricAvailable().timeout(const Duration(seconds: 3));
        if (isAvailable && !kIsWeb) {
          final authenticated = await bioAuth.authenticate().timeout(const Duration(seconds: 10));
          if (!authenticated) {
            _goToDashboard();
            return;
          }
        }
      } catch (_) {}
      _goToDashboard();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  void _goToDashboard() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.secondary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Custom Logo Placeholder (Modern & Unique)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded, 
                size: 60, 
                color: AppColors.primary
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Finance Flow',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 48),
            const SpinKitFoldingCube(
              color: Colors.white,
              size: 30.0,
            ),
          ],
        ),
      ),
    );
  }
}
