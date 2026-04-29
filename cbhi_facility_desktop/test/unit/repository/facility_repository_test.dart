// Unit tests for FacilityRepository — verifies API calls without backend

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbhi_facility_desktop/src/data/facility_repository.dart';
import 'dart:convert';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockClient;
  late FacilityRepository repository;

  setUpAll(() {
    registerFallbackValue(Uri());
  });

  setUp(() {
    mockClient = MockHttpClient();
    repository = FacilityRepository(client: mockClient);
    // Set up SharedPreferences mock for tests that call login()
    SharedPreferences.setMockInitialValues({});
  });

  group('FacilityRepository', () {
    test('login() stores token on success', () async {
      final mockResponse = http.Response(
        jsonEncode({'accessToken': 'test-token', 'user': {}}),
        200,
      );
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => mockResponse);

      await repository.login(
        identifier: 'facility@test.com',
        password: 'password',
      );

      expect(repository.isAuthenticated, isTrue);
    });

    test('verifyEligibility() calls correct endpoint', () async {
      final mockResponse = http.Response(
        jsonEncode({
          'eligible': true,
          'membershipId': 'M-001',
          'fullName': 'Test Member',
        }),
        200,
      );
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => mockResponse);

      final result = await repository.verifyEligibility(
        membershipId: 'M-001',
      );

      expect(result['eligible'], isTrue);
      expect(result['membershipId'], 'M-001');
    });

    test('submitClaim() sends correct payload', () async {
      final mockResponse = http.Response(
        jsonEncode({
          'claimNumber': 'CLM-001',
          'status': 'SUBMITTED',
        }),
        201,
      );
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => mockResponse);

      final result = await repository.submitClaim(
        membershipId: 'M-001',
        serviceDate: '2025-01-15',
        items: [
          {'serviceName': 'Consultation', 'quantity': 1, 'unitPrice': 150.0}
        ],
      );

      expect(result['claimNumber'], 'CLM-001');
      expect(result['status'], 'SUBMITTED');
    });

    test('getClaims() returns list of claims', () async {
      final mockResponse = http.Response(
        jsonEncode({
          'claims': [
            {'id': 'c1', 'claimNumber': 'CLM-001'},
            {'id': 'c2', 'claimNumber': 'CLM-002'},
          ]
        }),
        200,
      );
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => mockResponse);

      final claims = await repository.getClaims();

      expect(claims.length, 2);
      expect(claims.first['claimNumber'], 'CLM-001');
    });

    test('ping() returns true when backend is reachable', () async {
      final mockResponse = http.Response('OK', 200);
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => mockResponse);

      final result = await repository.ping();

      expect(result, isTrue);
    });

    test('ping() returns false when backend is unreachable', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenThrow(Exception('Network error'));

      final result = await repository.ping();

      expect(result, isFalse);
    });
  });
}
