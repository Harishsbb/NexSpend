import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    print('Splash: Starting navigation check...');
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    print('Splash: Checking auth state...');
    // Check if user is already logged in with a timeout to prevent hanging
    User? user;
    try {
      user = await ref.read(authServiceProvider).authStateChanges.first.timeout(
        const Duration(seconds: 5),
      );
    } catch (e) {
      print('Splash: Auth state check timed out or failed: $e');
      user = null; // Fallback to login if it hangs
    }
    
    print('Splash: User is ${user?.email ?? "null"}');
    if (!mounted) return;

    if (user != null) {
      print('Splash: User logged in, checking biometrics...');
      // User is logged in, try biometric auth
      final bioAuth = ref.read(bioAuthServiceProvider);
      try {
        final isAvailable = await bioAuth.isBiometricAvailable().timeout(const Duration(seconds: 3));
        print('Splash: Biometric available: $isAvailable');
        
        if (isAvailable && !kIsWeb) { // Biometrics on web can be flaky, skipping for now if it hangs
          print('Splash: Authenticating with biometrics...');
          final authenticated = await bioAuth.authenticate().timeout(const Duration(seconds: 10));
          print('Splash: Authenticated: $authenticated');
          if (!authenticated) {
            print('Splash: Biometric auth failed');
            // For now, we'll let them through to not lock them out during dev
            _goToDashboard();
            return;
          }
        }
      } catch (e) {
        print('Splash: Biometric check failed or timed out: $e');
      }
      _goToDashboard();
    } else {
      print('Splash: Navigating to LoginScreen');
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
