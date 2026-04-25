// Web implementation of PasskeyService using dart:js_interop.
// No dart:io, no Platform references — compiles cleanly under dart2js.
// Uses js_interop_unsafe for dynamic property access on credential responses.

import 'dart:convert';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
    // Check if the credentials API is accessible (always non-null in modern browsers)
    web.window.navigator.credentials;
    return true;
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
    final challengeBytes = _decodeBase64Url(challenge);

    // Build the options JSON string and parse it as a JS object
    final allowCredentials = credentialIds.map((id) => {
      'type': 'public-key',
      'id': _base64UrlEncode(_decodeBase64Url(id)),
    }).toList();

    final optionsJson = jsonEncode({
      'publicKey': {
        'challenge': _base64UrlEncode(challengeBytes),
        'allowCredentials': allowCredentials,
        'userVerification': 'required',
        'timeout': 60000,
      },
    });

    // Use eval-style JS interop to call navigator.credentials.get()
    // We pass the options as a JSON-parsed JS object
    final jsOptions = _jsonToJSObject(optionsJson);
    final credentialOptions = jsOptions as web.CredentialRequestOptions;

    final credential = await web.window.navigator.credentials
        .get(credentialOptions)
        .toDart;

    if (credential == null) return null;

    final credObj = credential as JSObject;
    final response = credObj.getProperty('response'.toJS) as JSObject?;
    if (response == null) return null;

    return PasskeyAssertion(
      credentialId: _base64UrlEncode(_getArrayBufferBytes(credObj, 'rawId')),
      clientDataJSON: _base64UrlEncode(_getArrayBufferBytes(response, 'clientDataJSON')),
      authenticatorData: _base64UrlEncode(_getArrayBufferBytes(response, 'authenticatorData')),
      signature: _base64UrlEncode(_getArrayBufferBytes(response, 'signature')),
      userHandle: _tryGetArrayBufferBytes(response, 'userHandle') != null
          ? _base64UrlEncode(_getArrayBufferBytes(response, 'userHandle'))
          : null,
    );
  } catch (_) {
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
    final challengeBytes = _decodeBase64Url(challenge);
    final userIdBytes = utf8.encode(userId);

    final optionsJson = jsonEncode({
      'publicKey': {
        'challenge': _base64UrlEncode(challengeBytes),
        'rp': {'id': rpId, 'name': 'Maya City CBHI'},
        'user': {
          'id': _base64UrlEncode(userIdBytes),
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
      },
    });

    final jsOptions = _jsonToJSObject(optionsJson);
    final credentialOptions = jsOptions as web.CredentialCreationOptions;

    final credential = await web.window.navigator.credentials
        .create(credentialOptions)
        .toDart;

    if (credential == null) return null;

    final credObj = credential as JSObject;
    final response = credObj.getProperty('response'.toJS) as JSObject?;
    if (response == null) return null;

    return PasskeyAttestation(
      credentialId: _base64UrlEncode(_getArrayBufferBytes(credObj, 'rawId')),
      clientDataJSON: _base64UrlEncode(_getArrayBufferBytes(response, 'clientDataJSON')),
      attestationObject: _base64UrlEncode(_getArrayBufferBytes(response, 'attestationObject')),
    );
  } catch (_) {
    return null;
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Parse a JSON string into a JS object using JSON.parse via js_interop.
JSObject _jsonToJSObject(String json) {
  // Use the global JSON.parse function
  final jsonParse = globalContext.getProperty('JSON'.toJS) as JSObject;
  return jsonParse.callMethod('parse'.toJS, json.toJS) as JSObject;
}

List<int> _decodeBase64Url(String input) {
  final padded = input.padRight((input.length + 3) & ~3, '=');
  return base64Url.decode(padded);
}

String _base64UrlEncode(List<int> bytes) {
  if (bytes.isEmpty) return '';
  return base64Url.encode(bytes).replaceAll('=', '');
}

List<int> _getArrayBufferBytes(JSObject obj, String key) {
  try {
    final prop = obj.getProperty(key.toJS);
    if (prop == null || prop.isUndefinedOrNull) return [];
    // Convert ArrayBuffer to Uint8Array then to Dart list
    final uint8Array = _toUint8Array(prop as JSObject);
    return uint8Array.toDart.toList();
  } catch (_) {
    return [];
  }
}

List<int>? _tryGetArrayBufferBytes(JSObject obj, String key) {
  try {
    final prop = obj.getProperty(key.toJS);
    if (prop == null || prop.isUndefinedOrNull) return null;
    final uint8Array = _toUint8Array(prop as JSObject);
    return uint8Array.toDart.toList();
  } catch (_) {
    return null;
  }
}

/// Convert an ArrayBuffer or TypedArray to Uint8Array via JS.
JSUint8Array _toUint8Array(JSObject bufferOrArray) {
  // If it's already a Uint8Array, return as-is
  // Otherwise wrap in new Uint8Array(buffer)
  final uint8ArrayCtor = globalContext.getProperty('Uint8Array'.toJS) as JSObject;
  return uint8ArrayCtor.callMethod('from'.toJS, bufferOrArray) as JSUint8Array;
}
