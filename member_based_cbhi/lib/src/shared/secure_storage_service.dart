import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure token storage.
/// Uses flutter_secure_storage on mobile/desktop, SharedPreferences on web
/// (web has no keychain — tokens are short-lived there anyway).
///
/// Falls back to SharedPreferences on Android if the hardware Keystore is
/// unavailable (e.g., after a factory reset that invalidates encrypted keys,
/// or on devices without a TEE). This prevents a PlatformException from
/// crashing the app on launch.
class SecureStorageService {
  SecureStorageService._();
  static final SecureStorageService instance = SecureStorageService._();

  static const _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  final FlutterSecureStorage _secure = const FlutterSecureStorage(
    aOptions: _androidOptions,
  );

  // Prefix used when falling back to SharedPreferences so keys don't collide
  // with other SharedPreferences data.
  static const _fallbackPrefix = '_ss_fallback_';

  Future<void> write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
      return;
    }
    try {
      await _secure.write(key: key, value: value);
    } catch (_) {
      // Keystore unavailable — fall back to SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('$_fallbackPrefix$key', value);
    }
  }

  Future<String?> read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    }
    try {
      return await _secure.read(key: key);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('$_fallbackPrefix$key');
    }
  }

  Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
      return;
    }
    try {
      await _secure.delete(key: key);
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_fallbackPrefix$key');
    }
  }
}
