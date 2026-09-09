import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../utils/global_navigator.dart';
import '../screens/login_screen.dart';

class AuthService {
  // Émulateur Android  → 'http://10.0.2.2:8000'
  // Téléphone physique (via ADB Reverse USB) → 'http://127.0.0.1:8000'
  static const String baseUrl = 'http://127.0.0.1:8000';

  static String? _accessToken;
  static String? _refreshToken;
  static Map<String, dynamic>? _user;

  static String? get accessToken => _accessToken;
  static String? get refreshToken => _refreshToken;
  static Map<String, dynamic>? get user => _user;
  static bool get isAuthenticated => _accessToken != null;
  static bool get isAdmin => _user?['is_staff'] == true;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString('access_token');
    _refreshToken = prefs.getString('refresh_token');
    final userStr = prefs.getString('user');
    if (userStr != null) {
      try {
        _user = jsonDecode(userStr);
      } catch (e) {
        _user = null;
      }
    }
  }

  static Future<void> _saveAuthData(
    String access,
    String refresh,
    Map<String, dynamic> userData,
  ) async {
    _accessToken = access;
    _refreshToken = refresh;
    _user = userData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
    await prefs.setString('user', jsonEncode(userData));
  }

  static Future<void> logout() async {
    _accessToken = null;
    _refreshToken = null;
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user');
  }

  static Future<void> logoutAndRedirect() async {
    await logout();
    final context = navigatorKey.currentContext;
    if (context != null) {
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  // Inscription
  Future<Map<String, dynamic>> register({
    required String fullName,
    String? phoneNumber,
    String? email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final body = {
        'full_name': fullName,
        'password': password,
        'confirm_password': confirmPassword,
      };
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        body['phone_number'] = phoneNumber;
      }
      if (email != null && email.isNotEmpty) body['email'] = email;

      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.register}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (data['requires_otp'] == false && data['tokens'] != null) {
          await _saveAuthData(
            data['tokens']['access'],
            data['tokens']['refresh'],
            data['user'],
          );
        }
        return {
          'success': true,
          'message': data['message'],
          'phone_number': data['phone_number'],
          'requires_otp': data['requires_otp'] ?? true,
        };
      } else {
        return {'success': false, 'errors': data};
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'detail': 'Erreur de connexion au serveur : $e'},
      };
    }
  }

  // Connexion
  Future<Map<String, dynamic>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${ApiConfig.login}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'identifier': identifier, 'password': password}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['requires_otp'] == false && data['tokens'] != null) {
          await _saveAuthData(
            data['tokens']['access'],
            data['tokens']['refresh'],
            data['user'],
          );
        }
        return {
          'success': true,
          'message': data['message'],
          'phone_number': data['phone_number'],
          'requires_otp': data['requires_otp'] ?? true,
        };
      } else {
        return {'success': false, 'errors': data};
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'detail': 'Erreur de connexion au serveur : $e'},
      };
    }
  }

  // Connexion sociale (Google/Facebook)
  Future<Map<String, dynamic>> socialLogin({
    required String provider,
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/social-login/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'provider': provider, 'token': token}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        if (data['requires_phone'] == true) {
          return {
            'success': true,
            'requires_phone': true,
            'email': data['email'],
            'name': data['name'],
            'provider': data['provider'],
          };
        } else {
          await _saveAuthData(
            data['tokens']['access'],
            data['tokens']['refresh'],
            data['user'],
          );
          return {
            'success': true,
            'requires_phone': false,
            'message': data['message'],
            'user': data['user'],
          };
        }
      } else {
        return {'success': false, 'errors': data};
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'detail': 'Erreur serveur : $e'},
      };
    }
  }

  // Inscription sociale (avec ajout du téléphone)
  Future<Map<String, dynamic>> socialRegister({
    required String email,
    required String name,
    required String phoneNumber,
    required String provider,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/social-register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
          'phone_number': phoneNumber,
          'provider': provider,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'message': data['message'],
          'phone_number': data['phone_number'],
        };
      } else {
        return {'success': false, 'errors': data};
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'detail': 'Erreur serveur : $e'},
      };
    }
  }

  // Vérification OTP
  Future<Map<String, dynamic>> verifyOtp({
    required String phoneNumber,
    required String code,
    required String purpose, // 'register' ou 'login'
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/accounts/verify-otp/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone_number': phoneNumber,
          'code': code,
          'purpose': purpose,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        await _saveAuthData(
          data['tokens']['access'],
          data['tokens']['refresh'],
          data['user'],
        );
        return {
          'success': true,
          'message': data['message'],
          'user': data['user'],
        };
      } else {
        return {'success': false, 'errors': data};
      }
    } catch (e) {
      return {
        'success': false,
        'errors': {'detail': 'Erreur de connexion au serveur : $e'},
      };
    }
  }
}
