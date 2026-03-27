import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static const String _fallbackBaseUrl = String.fromEnvironment(
    'API_LAN_BASE_URL',
    defaultValue: 'https://your-app.onrender.com',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }
    if (!kIsWeb && Platform.isAndroid) {
      return _fallbackBaseUrl;
    }
    return _fallbackBaseUrl;
  }

  static const Duration _requestTimeout = Duration(seconds: 12);

  static Future<bool> signup(String name, String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/signup'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
            }),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> login(String email, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['access_token']?.toString() ?? '');
        await prefs.setString('user_email', email);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getStoredToken() async {
    return getToken();
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email');
  }

  static Future<bool> addTransaction(double amount, String category, String note) async {
    final token = await getToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl/transactions/add'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({
            'amount': amount,
            'category': category,
            'note': note,
          }),
        )
        .timeout(_requestTimeout);

    return response.statusCode == 200;
  }

  static Future<List<dynamic>> getTransactions() async {
    final token = await getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/transactions/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['transactions'] as List<dynamic>;
    }

    return [];
  }

  static Future<Map<String, dynamic>> getAnalytics() async {
    final token = await getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/analytics/summary'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    return {};
  }

  static Future<List<dynamic>> getInsights() async {
    final token = await getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/insights/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as Map<String, dynamic>)['insights'] as List<dynamic>;
    }

    return [];
  }

  static Future<Map<String, dynamic>> getAiAnalysis(String userId) async {
    final token = await getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/ai/results/$userId'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    return {};
  }

  static Future<bool> setBudget(String category, double limit) async {
    final token = await getToken();

    final response = await http
        .post(
          Uri.parse('$baseUrl/budget/set'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode({'category': category, 'limit': limit}),
        )
        .timeout(_requestTimeout);

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getBudgets() async {
    final token = await getToken();

    final response = await http
        .get(
          Uri.parse('$baseUrl/budget/'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    return {};
  }

  static Future<Map<String, dynamic>> getDashboardData(String token) async {
    final response = await http
        .get(
          Uri.parse('$baseUrl/dashboard'),
          headers: {'Authorization': 'Bearer $token'},
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }

    throw Exception('Failed to load dashboard');
  }

  static Future<bool> registerDeviceToken(String token) async {
    final userId = await getUserEmail();
    if (userId == null || userId.isEmpty) {
      return false;
    }
    return registerFcmToken(userId: userId, fcmToken: token);
  }

  static Future<bool> registerFcmToken({
    required String userId,
    required String fcmToken,
  }) async {
    final authToken = await getToken();
    if (authToken == null) {
      return false;
    }

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/notifications/token'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $authToken',
            },
            body: jsonEncode({'user_id': userId, 'fcm_token': fcmToken}),
          )
          .timeout(_requestTimeout);

      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
