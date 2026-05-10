// lib/providers/auth_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ruang_sehat/features/auth/data/auth_services.dart';
import 'package:ruang_sehat/features/auth/data/user_model.dart';
import 'package:ruang_sehat/features/auth/presentation/screens/auth_screens.dart';
import 'package:ruang_sehat/main.dart';

extension StringExtension on String {
  String capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  UserModel? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  UserModel? get user => _user;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _resetMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  Map<String, dynamic>? _safeJsonDecode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String _extractErrorMessage(http.Response response) {
    final body = _safeJsonDecode(response.body);
    if (body != null) {
      if (body['errors'] != null && body['errors'] is List) {
        final List errors = body['errors'];
        if (errors.isNotEmpty) {
          final messages = errors.map((e) {
            if (e is Map && e['message'] != null) {
              final field = e['field'];
              return field != null
                  ? '${e['message']} ($field)'
                  : e['message'].toString();
            }
            return e.toString();
          }).toList();
          return messages.join('\n');
        }
      }
      return body['message'] ??
          body['error'] ??
          'Request gagal (${response.statusCode})';
    }
    if (response.body.isNotEmpty && response.body.length < 200) {
      return 'Server error ${response.statusCode}: ${response.body}';
    }
    return 'Server error ${response.statusCode}';
  }

  Future<bool> register(String name, String username, String password) async {
    _setLoading(true);
    _resetMessages();

    try {
      final response = await AuthServices.register(name, username, password);

      debugPrint('REGISTER Status: ${response.statusCode}');
      debugPrint('REGISTER Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _safeJsonDecode(response.body);
        _successMessage =
            body?['message'] ?? 'Registrasi berhasil! Silakan login.';
        _setLoading(false);
        return true;
      } else {
        _errorMessage = _extractErrorMessage(response);
        _setLoading(false);
        return false;
      }
    } on FormatException catch (e) {
      _errorMessage = 'Format response tidak valid: ${e.message}';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _resetMessages();

    try {
      final response = await AuthServices.login(username, password);

      debugPrint('LOGIN Status: ${response.statusCode}');
      debugPrint('LOGIN Body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = _safeJsonDecode(response.body);
        if (body == null) {
          _errorMessage = 'Response server kosong atau tidak valid';
          _setLoading(false);
          return false;
        }

        final token = body['data']?['token'] ?? body['token'];
        final userData = body['data']?['user'] ?? body['user'];

        if (token == null || userData == null) {
          _errorMessage = 'Token atau data user tidak ditemukan di response';
          _setLoading(false);
          return false;
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token.toString());
        await prefs.setString('user', jsonEncode(userData));

        _user = UserModel.fromJson(
          userData is Map<String, dynamic>
              ? userData
              : Map<String, dynamic>.from(userData as Map),
        );
        _successMessage =
            body['message'] ?? 'Login berhasil! Selamat datang kembali.';
        _setLoading(false);
        return true;
      } else {
        _errorMessage = _extractErrorMessage(response);
        _setLoading(false);
        return false;
      }
    } on FormatException catch (e) {
      _errorMessage = 'Format response tidak valid: ${e.message}';
      _setLoading(false);
      return false;
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      _errorMessage = 'Token tidak ditemukan';
      notifyListeners();
      return;
    }

    try {
      final response = await AuthServices.logout(token);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await prefs.remove('token');
        await prefs.remove('user');
        _successMessage = data['message'] ?? 'Logout berhasil';
        _user = null;
      } else {
        _errorMessage = data['message'] ?? 'Terjadi kesalahan';
      }
    } catch (e) {
      _errorMessage = 'Gagal terhubung ke server: ${e.toString()}';
      await prefs.remove('token');
      await prefs.remove('user');
      _user = null;
    }

    notifyListeners();
  }

  Future<void> handleTokenInvalid() async {
    debugPrint('AUTH: Token invalid — clearing session');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
    _user = null;
    _errorMessage = 'Sesi Anda telah berakhir. Silakan login kembali.';
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 100), () {
      appNavigatorKey.currentState?.pushNamedAndRemoveUntil(
        AuthScreen.routeName,
        (route) => false,
      );
    });
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    return token != null;
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userString = prefs.getString('user');
    if (userString != null) {
      _user = UserModel.fromJson(jsonDecode(userString));
      notifyListeners();
    }
  }

  // Get Profile dari API
  Future<void> getProfile() async {
    _setLoading(true);
    _resetMessages();

    try {
      final result = await AuthServices.getProfile();
      _user = result;

      // Sinkronkan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user', jsonEncode(result.toJson()));

      _successMessage = 'Profile berhasil diambil';
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      debugPrint('GET PROFILE ERROR: $e');
      _errorMessage = e.toString();
      _setLoading(false);
      notifyListeners();
    }
  }

  // Update Profile via API
  Future<bool> updateProfile({
    required String name,
    required String username,
    String? password,
  }) async {
    _setLoading(true);
    _resetMessages();

    try {
      final updatedUser = await AuthServices.updateProfile(
        name: name,
        username: username,
        password: password,
      );

      // Update user data di provider (gabungkan dengan data lama)
      _user = _user?.copyWith(
            name: updatedUser.name,
            username: updatedUser.username,
            email: updatedUser.email,
          ) ??
          updatedUser;

      // Sinkronkan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      if (_user != null) {
        await prefs.setString('user', jsonEncode(_user!.toJson()));
      }

      _successMessage = 'Profil berhasil diperbarui';
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('UPDATE PROFILE ERROR: $e');
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _setLoading(false);
      notifyListeners();
      return false;
    }
  }
}