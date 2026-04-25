import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'secure_storage_service.dart';

/// Local PIN authentication service.
///
/// The PIN is stored as a SHA-256 hash in [flutter_secure_storage].
/// The raw PIN is NEVER sent to the server.
///
/// Lockout: after [maxFailAttempts] consecutive wrong PINs, PIN entry is
/// disabled until the user completes OTP recovery.
class PinService {
  static const _pinHashKey = 'cbhi_pin_hash';
  static const _pinFailCountKey = 'cbhi_pin_fail_count';
  static const _pinLockedKey = 'cbhi_pin_locked';

  static const int minLength = 4;
  static const int maxLength = 6;
  static const int maxFailAttempts = 5;

  // ── Storage helpers ────────────────────────────────────────────────────────

  static SecureStorageService get _store => SecureStorageService.instance;

  // ── PIN management ─────────────────────────────────────────────────────────

  /// Returns true if a PIN has been set on this device.
  static Future<bool> hasPin() async {
    final hash = await _store.read(_pinHashKey);
    return hash != null && hash.isNotEmpty;
  }

  /// Stores the PIN as a SHA-256 hash. Resets fail counter and lock.
  static Future<void> setPin(String pin) async {
    final hash = _hashPin(pin);
    await _store.write(_pinHashKey, hash);
    await _store.delete(_pinFailCountKey);
    await _store.delete(_pinLockedKey);
  }

  /// Verifies the entered PIN against the stored hash.
  /// Increments fail counter on mismatch; locks after [maxFailAttempts].
  /// Returns true on match, false on mismatch.
  /// Throws [PinLockedException] if already locked.
  static Future<bool> verifyPin(String pin) async {
    if (await isLocked()) throw const PinLockedException();

    final stored = await _store.read(_pinHashKey);
    if (stored == null) return false;

    final entered = _hashPin(pin);
    if (entered == stored) {
      await resetFailCount();
      return true;
    }

    // Wrong PIN — increment counter
    final count = await _getFailCount() + 1;
    await _store.write(_pinFailCountKey, count.toString());
    if (count >= maxFailAttempts) {
      await _store.write(_pinLockedKey, 'true');
    }
    return false;
  }

  /// Returns the number of remaining attempts before lockout.
  static Future<int> remainingAttempts() async {
    final count = await _getFailCount();
    return (maxFailAttempts - count).clamp(0, maxFailAttempts);
  }

  /// Returns true if PIN entry is locked due to too many failures.
  static Future<bool> isLocked() async {
    final locked = await _store.read(_pinLockedKey);
    return locked == 'true';
  }

  /// Resets fail counter and lock (called after successful OTP recovery).
  static Future<void> resetFailCount() async {
    await _store.delete(_pinFailCountKey);
    await _store.delete(_pinLockedKey);
  }

  /// Clears all PIN data (called on logout).
  static Future<void> clearPin() async {
    await _store.delete(_pinHashKey);
    await _store.delete(_pinFailCountKey);
    await _store.delete(_pinLockedKey);
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  static String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    return sha256.convert(bytes).toString();
  }

  static Future<int> _getFailCount() async {
    final raw = await _store.read(_pinFailCountKey);
    return int.tryParse(raw ?? '0') ?? 0;
  }
}

/// Thrown when PIN entry is locked after too many failed attempts.
class PinLockedException implements Exception {
  const PinLockedException();

  @override
  String toString() => 'PinLockedException: PIN entry is locked.';
}
