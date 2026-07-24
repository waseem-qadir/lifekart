import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  Map<String, dynamic>? _user;
  String? _accessToken;
  bool _isLoading = true;

  Map<String, dynamic>? get user => _user;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null;

  AuthProvider() {
    _loadStoredAuth();
  }

  Future<void> _loadStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        _user = jsonDecode(userStr);
      } catch (_) {}
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      _accessToken = response['access_token'];
      _user = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('refresh_token', response['refresh_token']);
      await prefs.setString('user', jsonEncode(_user));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> register(String fullName, String email, String password) async {
    try {
      final response = await _apiService.post('/auth/register', {
        'full_name': fullName,
        'email': email,
        'password': password,
        'role': 'customer',
      });

      _accessToken = response['access_token'];
      _user = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('refresh_token', response['refresh_token']);
      await prefs.setString('user', jsonEncode(_user));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  bool _isGoogleInitialized = false;

  Future<void> googleLogin() async {
    try {
      final googleSignIn = GoogleSignIn.instance;
      if (!_isGoogleInitialized) {
        await googleSignIn.initialize();
        _isGoogleInitialized = true;
      }

      final GoogleSignInAccount account = await googleSignIn.authenticate();
      
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null) {
        throw Exception('Failed to get Google ID token');
      }

      final response = await _apiService.post('/auth/google', {
        'credential': idToken,
      });

      _accessToken = response['access_token'];
      _user = response['user'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', _accessToken!);
      await prefs.setString('refresh_token', response['refresh_token']);
      await prefs.setString('user', jsonEncode(_user));

      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _accessToken = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
    notifyListeners();
  }
}
