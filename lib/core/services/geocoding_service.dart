import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

class GeocodingResult {
  final double latitude;
  final double longitude;
  final String displayName;
  final Map<String, dynamic> address;

  const GeocodingResult({
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.address,
  });

  factory GeocodingResult.fromJson(Map<String, dynamic> json) {
    final address = json['address'];
    return GeocodingResult(
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      displayName: json['display_name']?.toString() ?? '',
      address: address is Map<String, dynamic> ? address : const {},
    );
  }
}

class GeocodingService {
  GeocodingService._();

  static const _baseUrl = 'https://nominatim.openstreetmap.org';
  static const _headers = {
    'User-Agent': 'FDP-Flutter-App/1.0',
    'Accept': 'application/json',
  };
  static Future<void> _requestQueue = Future.value();
  static DateTime? _lastRequestAt;

  static Future<List<GeocodingResult>> searchAddress(String query) async {
    final response = await _get('/search', {
      'q': query,
      'format': 'jsonv2',
      'addressdetails': '1',
      'limit': '5',
      'countrycodes': 'in',
    });
    if (response is! List) {
      throw const FormatException('Invalid search response');
    }
    return response
        .whereType<Map<String, dynamic>>()
        .map(GeocodingResult.fromJson)
        .toList();
  }

  static Future<GeocodingResult?> reverseGeocode(
    double latitude,
    double longitude,
  ) async {
    final response = await _get('/reverse', {
      'lat': latitude.toString(),
      'lon': longitude.toString(),
      'format': 'jsonv2',
      'addressdetails': '1',
    });
    if (response is! Map<String, dynamic>) return null;
    return GeocodingResult.fromJson(response);
  }

  static Future<dynamic> _get(String path, Map<String, String> query) async {
    final previous = _requestQueue;
    final done = Completer<void>();
    _requestQueue = done.future;
    await previous;

    try {
      final lastRequest = _lastRequestAt;
      if (lastRequest != null) {
        final wait =
            const Duration(seconds: 1) - DateTime.now().difference(lastRequest);
        if (wait > Duration.zero) await Future<void>.delayed(wait);
      }

      _lastRequestAt = DateTime.now();
      final response = await http
          .get(
            Uri.parse('$_baseUrl$path').replace(queryParameters: query),
            headers: _headers,
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('Geocoding service returned ${response.statusCode}.');
      }
      return jsonDecode(response.body);
    } finally {
      done.complete();
    }
  }
}
