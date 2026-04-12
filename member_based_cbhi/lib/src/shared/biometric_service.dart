import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Biometric authentication service.
/// Supports fingerprint and face ID for returning users.
class BiometricService {
  static final _auth = LocalAuthentication();
  static const _biometricEnabledKey = 'cbhi_biometric_enabled';
  static const _biometricTokenKey = 'cbhi_biometric_token';

  /// Check if biometric authentication is available on this device
  static Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canCheck && isDeviceSupported;
    } catch (_) {
      return false;
    }
  }

  /// Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return [];
    }
  }

  /// Check if user has enabled biometric login
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable biometric login — stores the session token securely
  static Future<bool> enableBiometric(String accessToken) async {
    final available = await isAvailable();
    if (!available) return false;

    final authenticated = await authenticate(
      reason: 'Confirm your identity to enable biometric login',
    );
    if (!authenticated) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
    await prefs.setString(_biometricTokenKey, accessToken);
    return true;
  }

  /// Disable biometric login
  static Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove(_biometricTokenKey);
  }

  /// Authenticate with biometrics and return stored token if successful
  static Future<String?> authenticateAndGetToken() async {
    final enabled = await isBiometricEnabled();
    if (!enabled) return null;

    final authenticated = await authenticate(
      reason: 'Sign in to Maya City CBHI',
    );
    if (!authenticated) return null;

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_biometricTokenKey);
  }

  /// Perform biometric authentication
  static Future<bool> authenticate({required String reason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // Allow PIN fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
