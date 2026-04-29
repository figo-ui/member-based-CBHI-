// Unit tests for FacilityRepository
// Tests HTTP interactions with a mocked http.Client.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbhi_facility_desktop/src/data/facility_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

http.Response _jsonResponse(Map<String, dynamic> body, {int statusCode = 200}) {
  return http.Response(jsonEncode(body), statusCode,
      headers: {'content-type': 'application/json'});
}

http.Response _errorResponse(String message, {int statusCode = 400}) {
  return http.Response(
    jsonEncode({'message': message}),
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  // FacilityRepository.login() calls SharedPreferences.getInstance() to persist the token.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockClient;
  late FacilityRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockHttpClient();
    repository = FacilityRepository(client: mockClient);
  });

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('FacilityRepository.verifyEligibility', () {
    test('returns active coverage on success', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'eligible': true,
            'coverageStatus': 'ACTIVE',
            'memberName': 'Alemayehu Bekele',
            'membershipId': 'MEM-001',
            'householdCode': 'HH-001',
          }));

      final result = await repository.verifyEligibility(membershipId: 'MEM-001');
      expect(result['eligible'], isTrue);
      expect(result['coverageStatus'], 'ACTIVE');
    });

    test('throws on 404 member not found', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _errorResponse('Member not found', statusCode: 404));

      expect(
        () => repository.verifyEligibility(membershipId: 'UNKNOWN'),
        throwsA(isA<Exception>()),
      );
    });

    test('returns expired coverage status', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'eligible': false,
            'coverageStatus': 'EXPIRED',
            'memberName': 'Tigist Haile',
            'membershipId': 'MEM-002',
          }));

      final result = await repository.verifyEligibility(membershipId: 'MEM-002');
      expect(result['eligible'], isFalse);
      expect(result['coverageStatus'], 'EXPIRED');
    });

    test('throws on 500 server error', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _errorResponse('Internal server error', statusCode: 500));

      expect(
        () => repository.verifyEligibility(membershipId: 'MEM-001'),
        throwsA(isA<Exception>()),
      );
    });

    test('verifies by household code', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'eligible': true,
            'coverageStatus': 'ACTIVE',
            'householdCode': 'HH-001',
          }));

      final result = await repository.verifyEligibility(householdCode: 'HH-001');
      expect(result['eligible'], isTrue);
    });
  });

  group('FacilityRepository.submitClaim', () {
    test('returns claim number on success', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
            'id': 'clm-1',
            'claimNumber': 'CLM-2025-001',
            'status': 'SUBMITTED',
            'totalAmount': 500.0,
          }));

      final result = await repository.submitClaim(
        membershipId: 'MEM-001',
        serviceDate: '2025-06-01',
        items: [
          {'serviceName': 'Medical Consultation', 'quantity': 1, 'unitPrice': 150.0},
        ],
      );

      expect(result['claimNumber'], 'CLM-2025-001');
      expect(result['status'], 'SUBMITTED');
    });

    test('throws on 422 validation error', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _errorResponse(
            'Service items are required',
            statusCode: 422,
          ));

      expect(
        () => repository.submitClaim(
          membershipId: 'MEM-001',
          serviceDate: '2025-06-01',
          items: [],
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('throws on 500 server error', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _errorResponse('Internal server error', statusCode: 500));

      expect(
        () => repository.submitClaim(
          membershipId: 'MEM-001',
          serviceDate: '2025-06-01',
          items: [
            {'serviceName': 'Consultation', 'quantity': 1, 'unitPrice': 150.0},
          ],
        ),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('FacilityRepository.login', () {
    test('stores token on successful login', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
            'accessToken': 'tok_facility_abc',
            'tokenType': 'Bearer',
          }));

      await repository.login(
        identifier: '+251912345678',
        password: 'password123',
      );

      expect(repository.isAuthenticated, isTrue);
    });

    test('throws on 401 unauthorized', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _errorResponse('Invalid credentials', statusCode: 401));

      expect(
        () => repository.login(identifier: 'bad', password: 'bad'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('FacilityRepository.getClaims', () {
    test('returns list of claims on success', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'claims': [
              {'id': 'clm-1', 'claimNumber': 'CLM-001', 'status': 'SUBMITTED'},
              {'id': 'clm-2', 'claimNumber': 'CLM-002', 'status': 'APPROVED'},
            ],
          }));

      final claims = await repository.getClaims();
      expect(claims.length, 2);
    });
  });
}
