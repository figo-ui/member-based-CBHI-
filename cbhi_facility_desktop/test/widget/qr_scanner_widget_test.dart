// Widget tests for QR Scanner result parsing logic
// Note: QrScannerScreen itself cannot be widget-tested in unit test environment
// because mobile_scanner requires camera hardware. We test the QR payload
// parsing logic directly here.

import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';

void main() {
  group('QR payload parsing logic', () {
    // Mirrors the parsing logic in QrScannerScreen._onDetect
    Map<String, String?> parseQrPayload(String raw) {
      String? membershipId;
      String? householdCode;
      try {
        final jsonStart = raw.indexOf('{');
        if (jsonStart >= 0) {
          final jsonStr = raw.substring(jsonStart);
          final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
          householdCode = decoded['householdCode']?.toString();
          membershipId = decoded['membershipId']?.toString();
        } else {
          final parts = raw.split('.');
          if (parts.length == 3) {
            String padded = parts[1];
            while (padded.length % 4 != 0) {
              padded += '=';
            }
            final bodyJson = utf8.decode(
              base64Url.decode(padded.replaceAll('-', '+').replaceAll('_', '/')),
            );
            final decoded = jsonDecode(bodyJson) as Map<String, dynamic>;
            householdCode = decoded['householdCode']?.toString();
            membershipId = decoded['membershipId']?.toString();
          }
        }
      } catch (_) {
        // Parsing failed — graceful fallback
      }
      return {'membershipId': membershipId, 'householdCode': householdCode};
    }

    test('parses JSON QR payload correctly', () {
      final payload = jsonEncode({
        'membershipId': 'M-12345',
        'householdCode': 'HH-67890',
      });

      final result = parseQrPayload(payload);

      expect(result['membershipId'], 'M-12345');
      expect(result['householdCode'], 'HH-67890');
    });

    test('handles malformed QR payload gracefully', () {
      const payload = 'not-valid-json';

      final result = parseQrPayload(payload);

      expect(result['membershipId'], isNull);
      expect(result['householdCode'], isNull);
    });

    test('handles empty QR payload', () {
      const payload = '';

      final result = parseQrPayload(payload);

      expect(result['membershipId'], isNull);
      expect(result['householdCode'], isNull);
    });

    test('parses payload with only membershipId', () {
      final payload = jsonEncode({'membershipId': 'M-001'});

      final result = parseQrPayload(payload);

      expect(result['membershipId'], 'M-001');
      expect(result['householdCode'], isNull);
    });

    test('parses payload with only householdCode', () {
      final payload = jsonEncode({'householdCode': 'HH-001'});

      final result = parseQrPayload(payload);

      expect(result['membershipId'], isNull);
      expect(result['householdCode'], 'HH-001');
    });

    test('handles JSON embedded in larger string', () {
      final jsonPart = jsonEncode({'membershipId': 'M-999', 'householdCode': 'HH-999'});
      final payload = 'PREFIX:$jsonPart';

      final result = parseQrPayload(payload);

      expect(result['membershipId'], 'M-999');
      expect(result['householdCode'], 'HH-999');
    });
  });
}
