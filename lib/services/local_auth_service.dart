import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:sage/main.dart'; // Import main.dart to get 'prefs'

class LocalAuthService {
  final _auth = LocalAuthentication();

  // Check if biometric authentication is enabled in settings
  bool isAuthEnabled() {
    return prefs.getBool('enableBiometrics') ?? false;
  }

  // Toggle the setting
  Future<void> setAuthEnabled(bool value) async {
    await prefs.setBool('enableBiometrics', value);
  }

  // Check if the device has biometric hardware
  Future<bool> hasBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  // Trigger the authentication prompt
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Sage to continue',
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow non-biometric (screen lock) as well
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
