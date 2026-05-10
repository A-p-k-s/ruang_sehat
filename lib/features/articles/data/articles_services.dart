import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:ruang_sehat/features/articles/data/articles_model.dart';

class ArticlesServices {
  static String get _rawBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get baseUrl {
    if (_rawBaseUrl.isEmpty) {
      throw Exception('API_BASE_URL tidak ditemukan di assets/.env');
    }
    return _rawBaseUrl.replaceAll(RegExp(r'/+$'), '');
  }

  static String get articleBaseUrl => '$baseUrl/article';

  static VoidCallback? onTokenInvalid;

  static Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token tidak ditemukan');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  static dynamic _handleResponse(
    http.Response response, {
    bool allowEmpty404 = false,
  }) {
    debugPrint('ARTICLE API Status: ${response.statusCode}');
    debugPrint('ARTICLE API Body: ${response.body}');

    if (allowEmpty404 && response.statusCode == 404) {
      try {
        final decoded = jsonDecode(response.body);
        final msg = decoded['message']?.toString().toLowerCase() ?? '';
        final errorMsg = decoded['errors'] is List && decoded['errors'].isNotEmpty
            ? decoded['errors'][0]['message']?.toString().toLowerCase() ?? ''
            : '';
        if (msg.contains('kosong') ||
            msg.contains('not found') ||
            msg.contains('empty') ||
            errorMsg.contains('kosong') ||
            errorMsg.contains('not found') ||
            errorMsg.contains('empty')) {
          return {'articles': []};
        }
      } catch (_) {
        return {'articles': []};
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.body.trim().isEmpty) {
        throw Exception('Server error: ${response.statusCode} (response kosong)');
      }

      String errorMsg;
      try {
        final decoded = jsonDecode(response.body);
        errorMsg = decoded['message'] ?? decoded['error'] ?? 'Server error ${response.statusCode}';

        if (response.statusCode == 403) {
          final field = decoded['errors'] is List && decoded['errors'].isNotEmpty
              ? decoded['errors'][0]['field']?.toString().toLowerCase() ?? ''
              : '';
          final errMessage = decoded['errors'] is List && decoded['errors'].isNotEmpty
              ? decoded['errors'][0]['message']?.toString().toLowerCase() ?? ''
              : '';
          if (field.contains('token') || errMessage.contains('token tidak valid')) {
            onTokenInvalid?.call();
          }
        }
      } catch (_) {
        errorMsg = 'Server error: ${response.statusCode}';
      }
      throw Exception(errorMsg);
    }

    if (response.body.trim().isEmpty) {
      return null;
    }

    dynamic decode;
    try {
      decode = jsonDecode(response.body);
    } catch (e) {
      throw Exception('Format response tidak valid: ${e.toString()}');
    }

    if (decode is! Map<String, dynamic>) {
      return decode;
    }

    if (decode['success'] != true) {
      if (decode['errors'] != null && decode['errors'] is List && decode['errors'].isNotEmpty) {
        throw Exception(decode['errors'][0]['message']);
      } else {
        throw Exception(decode['message'] ?? 'Terjadi kesalahan');
      }
    }

    return decode['data'];
  }

  static Future<dynamic> _getRequest(
    String endpoint, {
    Map<String, String>? queryParameters,
    bool allowEmpty404 = false,
  }) async {
    final headers = await _getHeaders();
    var urlString = '$articleBaseUrl$endpoint';
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParameters).query;
      urlString += '?$queryString';
    }
    
    final url = Uri.parse(urlString);
    debugPrint('ARTICLE GET: $url');
    final response = await http.get(url, headers: headers);
    return _handleResponse(response, allowEmpty404: allowEmpty404);
  }

  static Future<dynamic> _postRequest(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$articleBaseUrl$endpoint');
    debugPrint('ARTICLE POST: $url');
    final response = await http.post(url, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  static Future<dynamic> _putRequest(String endpoint, Map<String, dynamic> body) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$articleBaseUrl$endpoint');
    debugPrint('ARTICLE PUT: $url');
    final response = await http.put(url, headers: headers, body: jsonEncode(body));
    return _handleResponse(response);
  }

  static Future<dynamic> _deleteRequest(String endpoint) async {
    final headers = await _getHeaders();
    final url = Uri.parse('$articleBaseUrl$endpoint');
    debugPrint('ARTICLE DELETE: $url');
    final response = await http.delete(url, headers: headers);
    return _handleResponse(response);
  }

  static Future<Map<String, dynamic>> getArticles({
    int page = 1,
    int limit = 10,
  }) async {
    final data = await _getRequest(
      '',
      queryParameters: {'page': page.toString(), 'limit': limit.toString()},
    );
    
    final List articles = data['articles'] ?? [];
    final int totalPages = data['totalPages'] ?? 1;
    
    return {
      'articles': articles.map((e) => ArticlesModel.fromJson(e)).toList(),
      'totalPages': totalPages,
    };
  }

  static Future<List<ArticlesModel>> getMyArticles() async {
    final data = await _getRequest('/user', allowEmpty404: true);
    final List articles = data is Map ? (data['articles'] ?? []) : (data is List ? data : []);
    return articles.map((e) => ArticlesModel.fromJson(e)).toList();
  }

  static Future<ArticlesModel> getDetailArticle(String id) async {
    final data = await _getRequest('/$id');
    return ArticlesModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  static Future<ArticlesModel> createArtikel({
    required File image,
    required String title,
    required String description,
    required String category,
  }) async {
    final uri = Uri.parse('$articleBaseUrl/create');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token tidak ditemukan');
    
    var request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['date'] = DateTime.now().toIso8601String();
    request.fields['category'] = category;
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = _handleResponse(response);
    return ArticlesModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  static Future<ArticlesModel> updateArticle(
    String id, {
    required String title,
    required String category,
    required String description,
  }) async {
    final data = await _putRequest('/$id', {
      'title': title,
      'category': category,
      'description': description,
    });
    return ArticlesModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  static Future<ArticlesModel> updateArticleWithImage(
    String id, {
    required File image,
    required String title,
    required String description,
    required String category,
  }) async {
    final uri = Uri.parse('$articleBaseUrl/$id');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    if (token == null) throw Exception('Token tidak ditemukan');
    
    var request = http.MultipartRequest('PUT', uri);
    request.headers['Authorization'] = 'Bearer $token';
    
    request.fields['title'] = title;
    request.fields['description'] = description;
    request.fields['category'] = category;
    request.files.add(await http.MultipartFile.fromPath('image', image.path));
    
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    
    final data = _handleResponse(response);
    return ArticlesModel.fromJson(data is Map<String, dynamic> ? data : {});
  }

  static Future<void> deleteArticle(String id) async {
    await _deleteRequest('/$id');
  }
}