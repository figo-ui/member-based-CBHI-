// Unit tests for AdminRepository
// Tests HTTP interactions with a mocked http.Client.

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cbhi_admin_desktop/src/data/admin_repository.dart';

class MockHttpClient extends Mock implements http.Client {}

// Helper to build a JSON response
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
  // AdminRepository.login() calls SharedPreferences.getInstance() to persist the token.
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHttpClient mockClient;
  late AdminRepository repository;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockClient = MockHttpClient();
    repository = AdminRepository(client: mockClient);
    // Inject a fake token so authorized requests work
    // We do this by calling login mock first
  });

  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('AdminRepository.login', () {
    test('returns response on successful login', () async {
      when(() => mockClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
            'accessToken': 'tok_abc123',
            'tokenType': 'Bearer',
          }));

      final result = await repository.login(
        identifier: '+251912345678',
        password: 'password123',
      );

      expect(result['accessToken'], 'tok_abc123');
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

  group('AdminRepository.getClaims', () {
    test('returns list of claims on success', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'claims': [
              {'id': 'clm-1', 'status': 'SUBMITTED', 'claimNumber': 'CLM-001'},
              {'id': 'clm-2', 'status': 'APPROVED', 'claimNumber': 'CLM-002'},
            ],
          }));

      final claims = await repository.getClaims();
      expect(claims.length, 2);
      expect(claims.first['claimNumber'], 'CLM-001');
    });

    test('throws on 500 server error', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _errorResponse('Internal server error', statusCode: 500));

      expect(() => repository.getClaims(), throwsA(isA<Exception>()));
    });

    test('throws on 401 unauthorized', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _errorResponse('Unauthorized', statusCode: 401));

      expect(() => repository.getClaims(), throwsA(isA<Exception>()));
    });
  });

  group('AdminRepository.reviewClaim', () {
    test('returns updated claim on approve success', () async {
      when(() => mockClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
            'id': 'clm-1',
            'status': 'APPROVED',
            'approvedAmount': 500.0,
          }));

      final result = await repository.reviewClaim(
        claimId: 'clm-1',
        status: 'APPROVED',
        approvedAmount: 500.0,
      );

      expect(result['status'], 'APPROVED');
    });

    test('returns updated claim on reject success', () async {
      when(() => mockClient.patch(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => _jsonResponse({
            'id': 'clm-1',
            'status': 'REJECTED',
            'decisionNote': 'Insufficient documentation',
          }));

      final result = await repository.reviewClaim(
        claimId: 'clm-1',
        status: 'REJECTED',
        decisionNote: 'Insufficient documentation',
      );

      expect(result['status'], 'REJECTED');
    });
  });

  group('AdminRepository.getPendingIndigent', () {
    test('returns list of pending applications on success', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'applications': [
              {'id': 'ind-1', 'status': 'PENDING_REVIEW', 'householdCode': 'HH-001'},
              {'id': 'ind-2', 'status': 'PENDING_REVIEW', 'householdCode': 'HH-002'},
            ],
          }));

      final apps = await repository.getPendingIndigent();
      expect(apps.length, 2);
      expect(apps.first['householdCode'], 'HH-001');
    });

    test('returns empty list when no pending applications', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({'applications': []}));

      final apps = await repository.getPendingIndigent();
      expect(apps, isEmpty);
    });
  });

  group('AdminRepository.getAllGrievances', () {
    test('returns list of grievances on success', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'grievances': [
              {'id': 'grv-1', 'status': 'OPEN', 'subject': 'Test grievance'},
            ],
          }));

      final grievances = await repository.getAllGrievances();
      expect(grievances.length, 1);
      expect(grievances.first['subject'], 'Test grievance');
    });
  });

  group('AdminRepository.getAllAppeals', () {
    test('returns list of appeals on success', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => _jsonResponse({
            'appeals': [
              {'id': 'app-1', 'status': 'PENDING', 'claimNumber': 'CLM-001'},
            ],
          }));

      final appeals = await repository.getAllAppeals();
      expect(appeals.length, 1);
      expect(appeals.first['claimNumber'], 'CLM-001');
    });
  });
}
