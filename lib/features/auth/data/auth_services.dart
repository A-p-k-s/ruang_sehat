// lib/features/auth/data/auth_services.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruang_sehat/features/auth/data/user_model.dart';

class AuthServices {
  static Uri _buildUri(String path) {
    final url = dotenv.env['API_BASE_URL'] ?? '';

    if (url.isEmpty) {
      debugPrint('ERROR: API_BASE_URL tidak ditemukan di assets/.env');
      throw Exception('API_BASE_URL belum diatur di assets/.env');
    }

    final cleanBase =
        url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    return Uri.parse('$cleanBase$path');
  }

  // Fungsi Service Register
  static Future<http.Response> register(
    String name,
    String username,
    String password,
  ) async {
    final url = _buildUri('/auth/register');
    debugPrint('REGISTER URL: $url');

    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "name": name,
        "username": username,
        "password": password,
        "appSource": "kesehatan",
      }),
    );
  }

  // Fungsi Service Login
  static Future<http.Response> login(String username, String password) async {
    final url = _buildUri('/auth/login');
    debugPrint('LOGIN URL: $url');

    return await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "username": username,
        "password": password,
        "appSource": "kesehatan",
      }),
    );
  }

  // Fungsi Service Logout
  static Future<http.Response> logout(String token) async {
    final url = _buildUri('/auth/logout');
    debugPrint('LOGOUT URL: $url');

    return await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  // Fungsi Service Get Profile
  static Future<UserModel> getProfile() async {
    final url = _buildUri('/auth/profile');
    debugPrint('GET PROFILE URL: $url');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('GET PROFILE Status: ${response.statusCode}');
    debugPrint('GET PROFILE Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'];
      return UserModel.fromJson(data);
    } else {
      throw Exception('Gagal mengambil profil: ${response.statusCode}');
    }
  }

  // Fungsi Service Update Profile
  static Future<UserModel> updateProfile({
    required String name,
    required String username,
    String? password,
  }) async {
    final url = _buildUri('/auth/profile');
    debugPrint('UPDATE PROFILE URL: $url');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token tidak ditemukan');
    }

    // Body request - hanya kirim password jika diisi
    final Map<String, dynamic> body = {
      'name': name,
      'username': username,
    };

    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    debugPrint('UPDATE PROFILE Status: ${response.statusCode}');
    debugPrint('UPDATE PROFILE Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      final data = decoded['data'] ?? decoded;
      return UserModel.fromJson(data);
    } else {
      try {
        final decoded = json.decode(response.body);
        throw Exception(decoded['message'] ?? 'Gagal update profil');
      } catch (_) {
        throw Exception('Gagal update profil: ${response.statusCode}');
      }
    }
  }
}