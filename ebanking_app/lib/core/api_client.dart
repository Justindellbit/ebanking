import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static void clearTokenCache() {}
  static Future<void> refreshToken() async {}

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read(key: 'jwt_token');
      // Debug temporaire — à supprimer après résolution
      print('🔑 TOKEN IN STORAGE: ${token != null ? token.substring(0, 20) + "..." : "NULL ❌"}');
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Future<http.Response> get(String url, {bool auth = true}) async {
    try {
      final h = await _headers(auth: auth);
      print('📡 GET $url');
      print('📋 Authorization: ${h['Authorization'] ?? "MISSING ❌"}');
      return await http.get(Uri.parse(url), headers: h)
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  static Future<http.Response> post(String url,
      {Object? body, bool auth = true}) async {
    try {
      return await http.post(
        Uri.parse(url),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  static Future<http.Response> postWithParams(String url,
      Map<String, String> params, {bool auth = true}) async {
    try {
      final uri = Uri.parse(url).replace(queryParameters: params);
      return await http.post(uri, headers: await _headers(auth: auth))
          .timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('No internet connection');
    }
  }

  static Future<http.Response> patch(String url,
      {Object? body, bool auth = true}) async {
    try {
      return await http.patch(
        Uri.parse(url),
        headers: await _headers(auth: auth),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
    } on SocketException {
      throw Exception('No internet connection');
    }
  }
}