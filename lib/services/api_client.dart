import 'dart:convert';
import 'package:http/http.dart' as http;
import 'hive_service.dart';

class ApiClient {
  static const String baseUrl = 'http://127.0.0.1:5000/api';
  static const Duration _timeout = Duration(seconds: 8);
  final HiveService _hiveService = HiveService();

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
        .timeout(_timeout);
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
        .timeout(_timeout);
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
        .timeout(_timeout);
    return _processResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    final headers = await _getHeaders();
    final response = await http
        .delete(Uri.parse('$baseUrl$endpoint'), headers: headers)
        .timeout(_timeout);
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
