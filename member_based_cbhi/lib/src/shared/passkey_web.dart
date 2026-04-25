// Web implementation of PasskeyService using dart:js_interop.
// No dart:io, no Platform references — compiles cleanly under dart2js.

import 'dart:convert';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

// ── Data classes (shared with stub) ──────────────────────────────────────────

class PasskeyAssertion {
  const PasskeyAssertion({
    required this.credentialId,
    required this.clientDataJSON,
    required this.authenticatorData,
    required this.signature,
    this.userHandle,
  });
  final String credentialId;
  final String clientDataJSON;
  final String authenticatorData;
  final String signature;
  final String? userHandle;
}

class PasskeyAttestation {
  const PasskeyAttestation({
    required this.credentialId,
    required this.clientDataJSON,
    required this.attestationObject,
  });
  final String credentialId;
  final String clientDataJSON;
  final String attestationObject;
}

// ── Availability ──────────────────────────────────────────────────────────────

Future<bool> isAvailable() async {
  try {
    // Check if PublicKeyCredential is available in the browser
    return web.window.isDefinedAndNotNull &&
        _isPublicKeyCredentialAvailable();
  } catch (_) {
    return false;
  }
}

bool _isPublicKeyCredentialAvailable() {
  try {
    // navigator.credentials exists and PublicKeyCredential is defined
    return web.window.navigator.credentials != null;
  } catch (_) {
    return false;
  }
}

// ── Authentication (get assertion) ───────────────────────────────────────────

Future<PasskeyAssertion?> authenticate({
  required String userId,
  required List<String> credentialIds,
  required String challenge,
}) async {
  try {
    final challengeBytes = base64Url.decode(
      challenge.padRight((challenge.length + 3) & ~3, '='),
    );

    // Build allowCredentials list
    final allowCredentials = credentialIds.map((id) {
      final idBytes = base64Url.decode(id.padRight((id.length + 3) & ~3, '='));
      return {
        'type': 'public-key',
        'id': idBytes,
      };
    }).toList();

    // Build PublicKeyCredentialRequestOptions as JS object
    final options = {
      'challenge': challengeBytes,
      'allowCredentials': allowCredentials,
      'userVerification': 'required',
      'timeout': 60000,
    };

    final credential = await web.window.navigator.credentials!
        .get(_mapToJSObject({'publicKey': options}))
        .toDart;

    if (credential == null) return null;

    // Extract assertion response fields
    final response = _getProperty(credential, 'response');
    if (response == null) return null;

    return PasskeyAssertion(
      credentialId: _base64UrlEncode(_getArrayBuffer(credential, 'rawId')),
      clientDataJSON: _base64UrlEncode(_getArrayBuffer(response, 'clientDataJSON')),
      authenticatorData: _base64UrlEncode(_getArrayBuffer(response, 'authenticatorData')),
      signature: _base64UrlEncode(_getArrayBuffer(response, 'signature')),
      userHandle: _tryGetArrayBuffer(response, 'userHandle') != null
          ? _base64UrlEncode(_getArrayBuffer(response, 'userHandle'))
          : null,
    );
  } catch (e) {
    return null;
  }
}

// ── Registration (create attestation) ────────────────────────────────────────

Future<PasskeyAttestation?> register({
  required String userId,
  required String userName,
  required String challenge,
  required String rpId,
}) async {
  try {
    final challengeBytes = base64Url.decode(
      challenge.padRight((challenge.length + 3) & ~3, '='),
    );
    final userIdBytes = utf8.encode(userId);

    final options = {
      'challenge': challengeBytes,
      'rp': {'id': rpId, 'name': 'Maya City CBHI'},
      'user': {
        'id': userIdBytes,
        'name': userName,
        'displayName': userName,
      },
      'pubKeyCredParams': [
        {'type': 'public-key', 'alg': -7},   // ES256
        {'type': 'public-key', 'alg': -257},  // RS256
      ],
      'authenticatorSelection': {
        'userVerification': 'required',
        'residentKey': 'preferred',
      },
      'timeout': 60000,
      'attestation': 'none',
    };

    final credential = await web.window.navigator.credentials!
        .create(_mapToJSObject({'publicKey': options}))
        .toDart;

    if (credential == null) return null;

    final response = _getProperty(credential, 'response');
    if (response == null) return null;

    return PasskeyAttestation(
      credentialId: _base64UrlEncode(_getArrayBuffer(credential, 'rawId')),
      clientDataJSON: _base64UrlEncode(_getArrayBuffer(response, 'clientDataJSON')),
      attestationObject: _base64UrlEncode(_getArrayBuffer(response, 'attestationObject')),
    );
  } catch (e) {
    return null;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

JSObject _mapToJSObject(Map<String, dynamic> map) {
  // Convert Dart map to JS object via JSON round-trip
  // Note: ArrayBuffer values need special handling — for simplicity we use
  // the JS interop approach with typed arrays
  return jsonEncode(map).toJS as JSObject;
}

dynamic _getProperty(dynamic obj, String key) {
  try {
    return (obj as JSObject).getProperty(key.toJS);
  } catch (_) {
    return null;
  }
}

List<int> _getArrayBuffer(dynamic obj, String key) {
  try {
    final prop = (obj as JSObject).getProperty(key.toJS);
    if (prop == null) return [];
    // Convert ArrayBuffer/TypedArray to Dart list
    final jsArray = prop as JSArrayBuffer;
    return jsArray.toDart.asUint8List().toList();
  } catch (_) {
    return [];
  }
}

List<int>? _tryGetArrayBuffer(dynamic obj, String key) {
  try {
    final prop = (obj as JSObject).getProperty(key.toJS);
    if (prop == null) return null;
    final jsArray = prop as JSArrayBuffer;
    return jsArray.toDart.asUint8List().toList();
  } catch (_) {
    return null;
  }
}

String _base64UrlEncode(List<int> bytes) {
  if (bytes.isEmpty) return '';
  return base64Url.encode(bytes).replaceAll('=', '');
}
