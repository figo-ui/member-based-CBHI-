import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String kAdminApiBase = String.fromEnvironment(
  'CBHI_API_BASE_URL',
  defaultValue: 'http://localhost:3000/api/v1',
);

class AdminRepository {
  AdminRepository({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  static const _tokenKey = 'cbhi_admin_token';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_tokenKey);
  }

  bool get isAuthenticated => _token != null && _token!.isNotEmpty;

  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    final response = await _post('/auth/login', {
      'identifier': identifier,
      'password': password,
    });
    _token = response['accessToken']?.toString();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, _token ?? '');
    return response;
  }

  Future<void> logout() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  Future<Map<String, dynamic>> getSummaryReport({
    String? from,
    String? to,
  }) async {
    final query = <String, String>{
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    final qs = query.isEmpty ? '' : '?${Uri(queryParameters: query).query}';
    return _get('/admin/reports/summary$qs');
  }

  Future<List<Map<String, dynamic>>> getClaims() async {
    final response = await _get('/admin/claims');
    return _asList(response['claims']);
  }

  Future<Map<String, dynamic>> reviewClaim({
    required String claimId,
    required String status,
    double? approvedAmount,
    String? decisionNote,
  }) async {
    return _patch('/admin/claims/$claimId/decision', {
      'status': status,
      if (approvedAmount != null) 'approvedAmount': approvedAmount,
      if (decisionNote != null) 'decisionNote': decisionNote,
    });
  }

  Future<List<Map<String, dynamic>>> getConfiguration() async {
    final response = await _get('/admin/configuration');
    return _asList(response['settings']);
  }

  Future<void> updateConfiguration({
    required String key,
    required Map<String, dynamic> value,
    String? label,
    String? description,
  }) async {
    await _put('/admin/configuration/$key', {
      'value': value,
      if (label != null) 'label': label,
      if (description != null) 'description': description,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingIndigent() async {
    final response = await _get('/admin/indigent/pending');
    return _asList(response['applications']);
  }

  Future<void> reviewIndigent({
    required String applicationId,
    required String status,
    String? reason,
  }) async {
    await _patch('/admin/indigent/$applicationId/review', {
      'status': status,
      if (reason != null) 'reason': reason,
    });
  }

  Future<String> exportCsv({
    required String type,
    String? from,
    String? to,
  }) async {
    final query = <String, String>{
      'type': type,
      if (from != null) 'from': from,
      if (to != null) 'to': to,
    };
    final qs = '?${Uri(queryParameters: query).query}';
    final response = await _client.get(
      Uri.parse('$kAdminApiBase/admin/export$qs'),
      headers: _headers,
    );
    if (response.statusCode != 200) throw Exception('Export failed');
    return response.body;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> _get(String path) async {
    final response = await _client.get(
      Uri.parse('$kAdminApiBase$path'),
      headers: _headers,
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.post(
      Uri.parse('$kAdminApiBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> _patch(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.patch(
      Uri.parse('$kAdminApiBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Future<Map<String, dynamic>> _put(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.put(
      Uri.parse('$kAdminApiBase$path'),
      headers: _headers,
      body: jsonEncode(body),
    );
    return _parse(response);
  }

  Map<String, dynamic> _parse(http.Response response) {
    final body = jsonDecode(response.body);
    if (response.statusCode >= 400) {
      throw Exception((body as Map)['message']?.toString() ?? 'Request failed');
    }
    return (body as Map).cast<String, dynamic>();
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    return (value as List? ?? [])
        .map((item) => (item as Map).cast<String, dynamic>())
        .toList();
  }
}
