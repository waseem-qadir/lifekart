import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator connecting to local host, or localhost for iOS simulator
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://localhost:8000/api/v1';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<bool> _refreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        await prefs.setString('access_token', data['access_token']);
        await prefs.setString('refresh_token', data['refresh_token']);
        return true;
      }
      
      // If refresh fails, clear tokens so the user is forced to log in again
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> get(String endpoint) async {
    var response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );
    
    if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
      final success = await _refreshToken();
      if (success) {
        // Retry the original request
        response = await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
        );
      }
    }
    
    return _handleResponse(response);
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> body) async {
    var response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
      final success = await _refreshToken();
      if (success) {
        // Retry the original request
        response = await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        );
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> body) async {
    var response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
      final success = await _refreshToken();
      if (success) {
        // Retry the original request
        response = await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        );
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> patch(String endpoint, Map<String, dynamic> body) async {
    var response = await http.patch(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
      final success = await _refreshToken();
      if (success) {
        // Retry the original request
        response = await http.patch(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
          body: jsonEncode(body),
        );
      }
    }

    return _handleResponse(response);
  }

  Future<dynamic> delete(String endpoint) async {
    var response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 401 && !endpoint.contains('/auth/')) {
      final success = await _refreshToken();
      if (success) {
        response = await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: await _getHeaders(),
        );
      }
    }

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isNotEmpty) {
        return jsonDecode(response.body);
      }
      return null;
    } else {
      String message = 'API Error';
      try {
        final errorBody = jsonDecode(response.body);
        message = errorBody['detail'] ?? errorBody['message'] ?? message;
      } catch (_) {}
      throw Exception(message);
    }
  }
}
