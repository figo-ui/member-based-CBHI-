// Stub implementation for non-web platforms.
// All methods return null/false — passkeys are web-only.

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

Future<bool> isAvailable() async => false;

Future<PasskeyAssertion?> authenticate({
  required String userId,
  required List<String> credentialIds,
  required String challenge,
}) async => null;

Future<PasskeyAttestation?> register({
  required String userId,
  required String userName,
  required String challenge,
  required String rpId,
}) async => null;
