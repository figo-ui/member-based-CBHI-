// Conditional import dispatcher for PasskeyService.
// On web: uses dart:js_interop via passkey_web.dart
// On mobile: uses passkey_stub.dart (returns null/false)
//
// No dart:io, no Platform references — web-safe.

import 'passkey_stub.dart'
    if (dart.library.js_interop) 'passkey_web.dart' as impl;

export 'passkey_stub.dart'
    if (dart.library.js_interop) 'passkey_web.dart'
    show PasskeyAssertion, PasskeyAttestation;

/// Passkey (WebAuthn) authentication service.
/// Available on Flutter Web only. All methods return null/false on mobile.
class PasskeyService {
  /// Returns true if passkeys are supported in the current environment.
  static Future<bool> isAvailable() => impl.isAvailable();

  /// Authenticates using an existing passkey credential.
  /// Returns null if authentication fails or is cancelled.
  static Future<impl.PasskeyAssertion?> authenticate({
    required String userId,
    required List<String> credentialIds,
    required String challenge,
  }) =>
      impl.authenticate(
        userId: userId,
        credentialIds: credentialIds,
        challenge: challenge,
      );

  /// Registers a new passkey credential.
  /// Returns null if registration fails or is cancelled.
  static Future<impl.PasskeyAttestation?> register({
    required String userId,
    required String userName,
    required String challenge,
    required String rpId,
  }) =>
      impl.register(
        userId: userId,
        userName: userName,
        challenge: challenge,
        rpId: rpId,
      );
}
