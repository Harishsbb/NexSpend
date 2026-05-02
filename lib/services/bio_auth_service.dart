import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bioAuthServiceProvider = Provider((ref) => BioAuthService());

class BioAuthService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isBiometricAvailable() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      if (!await isBiometricAvailable()) return false;

      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access your account',
      );
    } on PlatformException catch (_) {
      return false;
    }
  }
}
