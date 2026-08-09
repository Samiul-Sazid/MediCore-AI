import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'hive_service.dart';

class ApiClient {
  static const Duration _defaultTimeout = Duration(seconds: 10);
  static const Duration _longTimeout = Duration(seconds: 30);
  final HiveService _hiveService = HiveService();

  /// Endpoints that may take longer (AI, OCR).
  static const _slowEndpoints = ['/chat', '/ocr/parse', '/drugs/check-interaction'];

  /// Detect the correct base URL depending on platform.
  /// - Web / Desktop / iOS Simulator: localhost
  /// - Android Emulator: 10.0.2.2 (special alias for host loopback)
  /// - Physical device: needs custom IP (settable via Hive)
  static String get baseUrl {
    // Check for user-configured override first
    try {
      final hive = HiveService();
      final box = hive.getBox(HiveService.boxAppSettings);
      final custom = box.get('custom_api_url');
      if (custom != null && custom.toString().isNotEmpty) {
        return custom.toString();
      }
    } catch (_) {}

    // Platform-specific defaults
    if (kIsWeb) {
      return 'http://127.0.0.1:5000/api';
    }

    try {
      if (Platform.isAndroid) {
        return 'http://10.0.2.2:5000/api';
      }
    } catch (_) {}

    return 'http://127.0.0.1:5000/api';
  }

  Duration _getTimeout(String endpoint) {
    for (var slow in _slowEndpoints) {
      if (endpoint.contains(slow)) return _longTimeout;
    }
    return _defaultTimeout;
  }

  Future<Map<String, String>> _getHeaders() async {
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
    };

    // Check if user is logged in
    final authData = _hiveService.getItem(HiveService.boxAccounts, 'session');
    if (authData != null && authData['token'] != null) {
      headers['Authorization'] = 'Bearer ${authData['token']}';
    }

    return headers;
  }

  Future<dynamic> get(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .get(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(_getTimeout(endpoint));
    return _processResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_getTimeout(endpoint));
    return _processResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: headers,
          body: jsonEncode(body),
        )
        .timeout(_getTimeout(endpoint));
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(_getTimeout(endpoint));
    return _processResponse(response);
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'Error ${response.statusCode}';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson['error'] != null) {
          errorMessage = errorJson['error'];
        }
      } catch (_) {}
      throw Exception(errorMessage);
    }
  }
}
