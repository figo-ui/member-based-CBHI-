import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';


@immutable
class LocationItem {
  const LocationItem({
    required this.id,
    required this.name,
    required this.code,
    this.nameAmharic,
  });

  final String id;
  final String name;
  final String code;
  final String? nameAmharic;

  factory LocationItem.fromJson(Map<String, dynamic> json) {
    return LocationItem(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      nameAmharic: json['nameAmharic']?.toString(),
    );
  }

  String displayName(String languageCode) {
    if (languageCode == 'am' && (nameAmharic?.isNotEmpty ?? false)) {
      return nameAmharic!;
    }
    return name;
  }
}

class LocationService {
  LocationService({required this.apiBaseUrl});

  final String apiBaseUrl;

  Future<List<LocationItem>> fetchRegions() async {
    return _fetch('/locations/regions');
  }

  Future<List<LocationItem>> fetchZones(String regionCode) async {
    return _fetch('/locations/zones?regionCode=$regionCode');
  }

  Future<List<LocationItem>> fetchWoredas(String zoneCode) async {
    return _fetch('/locations/woredas?zoneCode=$zoneCode');
  }

  Future<List<LocationItem>> fetchKebeles(String woredaCode) async {
    return _fetch('/locations/kebeles?woredaCode=$woredaCode');
  }

  Future<List<LocationItem>> _fetch(String path) async {
    try {
      final response = await http.get(
        Uri.parse('$apiBaseUrl$path'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as List;
      return data
          .map((item) => LocationItem.fromJson((item as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
