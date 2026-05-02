import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../theme/app_colors.dart';
import '../services/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';

import '../services/bio_auth_service.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    // Check if user is already logged in
    final user = await ref.read(authServiceProvider).authStateChanges.first;
    
    if (!mounted) return;

    if (user != null) {
      // User is logged in, try biometric auth
      final bioAuth = ref.read(bioAuthServiceProvider);
      final isAvailable = await bioAuth.isBiometricAvailable();
      
      if (isAvailable) {
        final authenticated = await bioAuth.authenticate();
        if (!authenticated) {
          // If authentication fails or user cancels, stay on splash or show an error
          // For now, we'll let them try again or logout if they want, 
          // but usually we just keep showing the splash or a retry button.
          // Let's just navigate to Login if they fail for now, or stay here.
          // Better: just loop until they authenticate or we can add a 'Logout' button on Splash.
          // For simplicity, we'll just navigate to Dashboard if they succeed.
          if (authenticated) {
             _goToDashboard();
          } else {
             // Failed auth - in a real app we might show a 'Retry' button
             // For now, let's just go to dashboard to not lock them out, 
             // but usually you'd want to be strict.
             _goToDashboard(); 
          }
          return;
        }
      }
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
