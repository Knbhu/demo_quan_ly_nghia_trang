import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  ApiService._();
  static final ApiService instance = ApiService._();
  static const _requestTimeout = Duration(seconds: 20);
  String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000/api/v1';
    return defaultTargetPlatform == TargetPlatform.android
        ? 'http://10.0.2.2:3000/api/v1'
        : 'http://localhost:3000/api/v1';
  }

  Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token'
    };
  }

  Future<dynamic> get(String path) async {
    try {
      return _decode(await http
          .get(Uri.parse('$baseUrl$path'), headers: await _headers())
          .timeout(_requestTimeout));
    } on TimeoutException {
      throw Exception(
          'Máy chủ phản hồi quá lâu. Hãy kiểm tra backend và thử lại.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      return _decode(await http
          .post(Uri.parse('$baseUrl$path'),
              headers: await _headers(), body: jsonEncode(body))
          .timeout(_requestTimeout));
    } on TimeoutException {
      throw Exception(
          'Máy chủ phản hồi quá lâu. Hãy kiểm tra backend và thử lại.');
    }
  }

  dynamic _decode(http.Response response) {
    final content = response.body.trim();
    dynamic body = <String, dynamic>{};
    if (content.isNotEmpty) {
      try {
        body = jsonDecode(content);
      } on FormatException {
        final isHtml = content.startsWith('<!DOCTYPE') ||
            content.startsWith('<html') ||
            response.headers['content-type']?.contains('text/html') == true;
        if (isHtml) {
          throw Exception(
              'Backend đang chạy chưa có API này. Hãy dừng server cũ và chạy lại node server.js tại thư mục backend.');
        }
        throw Exception('Máy chủ trả dữ liệu không đúng định dạng JSON.');
      }
    }
    if (response.statusCode >= 400) {
      final dynamic rawMessage = body is Map
          ? (body['error'] ?? body['detail'] ?? body['message'])
          : body is String
              ? body
              : null;
      final message = rawMessage is String && rawMessage.trim().isNotEmpty
          ? rawMessage.trim()
          : 'Yêu cầu không thành công (${response.statusCode}).';
      throw Exception(message);
    }
    return body;
  }

  Future<void> saveToken(String token) async =>
      (await SharedPreferences.getInstance()).setString('access_token', token);
  Future<void> clearToken() async =>
      (await SharedPreferences.getInstance()).remove('access_token');
}
