import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';
import '../models/jwt_response.dart';

class AuthService {

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _tokenKey    = 'jwt_token';
  static const _usernameKey = 'saved_username';
  static const _roleKey     = 'user_role';

  // ─────────────────────────────────────────────────────
  // REGISTER
  // ─────────────────────────────────────────────────────
  Future<AuthResult> register(
    String username,
    String email,
    String password, {
    String firstName   = '',
    String lastName    = '',
    String phone       = '',
    bool   fa2Enabled  = false,
    String accountType = 'CHECKING',
    String currency    = 'USD',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.authUrl}/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username':    username.trim(),
          'email':       email.trim(),
          'password':    password,
          'firstName':   firstName.trim(),
          'lastName':    lastName.trim(),
          'phone':       phone.trim(),
          'fa2Enabled':  fa2Enabled,
          'accountType': accountType,
          'currency':    currency,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) return AuthResult.success();

      final body = _tryDecodeBody(response.body);
      final msg  = body?['message'] ?? body?['error'] ?? 'Registration failed';
      return AuthResult.failure(msg.toString());
    } on SocketException catch (e) {
      return AuthResult.failure('Connection failed: ${e.message}');
    } catch (e) {
      return AuthResult.failure('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────
  Future<LoginResult> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.authUrl}/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username.trim(),
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResult.success(JwtResponse.fromJson(data));
      }
      if (response.statusCode == 401) {
        return LoginResult.failure('Invalid username or password');
      }
      final body = _tryDecodeBody(response.body);
      final msg  = body?['message'] ?? body?['error'] ?? 'Login failed';
      return LoginResult.failure(msg.toString());
    } on SocketException catch (e) {
      return LoginResult.failure('Connection failed: ${e.message}');
    } catch (e) {
      return LoginResult.failure('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────
  // 2FA — Setup
  // ─────────────────────────────────────────────────────
  Future<String?> setup2FA() async {
    try {
      final token = await getToken();
      if (token == null) return null;
      final response = await http.post(
        Uri.parse('${AppConstants.authUrl}/2fa/setup'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['secret'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────────────────
  // 2FA — Disable
  // ─────────────────────────────────────────────────────
  Future<bool> disable2FA() async {
    try {
      final token = await getToken();
      if (token == null) return false;
      final response = await http.post(
        Uri.parse('${AppConstants.authUrl}/2fa/disable'),
        headers: {
          'Content-Type':  'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─────────────────────────────────────────────────────
  // 2FA — Vérifier le code SMS reçu par téléphone
  // ─────────────────────────────────────────────────────
  Future<LoginResult> validate2FA(String username, int code) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConstants.authUrl}/verify-sms'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'code': code.toString(), // SMS code est un String côté backend
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return LoginResult.success(JwtResponse.fromJson(data));
      }
      final body = _tryDecodeBody(response.body);
      final msg  = body?['error'] ?? 'Invalid or expired SMS code';
      return LoginResult.failure(msg.toString());
    } on SocketException catch (e) {
      return LoginResult.failure('Connection failed: ${e.message}');
    } catch (e) {
      return LoginResult.failure('Error: $e');
    }
  }

  // ─────────────────────────────────────────────────────
  // TOKEN MANAGEMENT
  // ─────────────────────────────────────────────────────
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
    // Debug: vérifier que le token est bien sauvegardé
    final verify = await _storage.read(key: _tokenKey);
    print('💾 TOKEN SAVED: ${verify != null ? "OK ✅ (${verify.substring(0, 20)}...)" : "FAILED ❌"}');
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> saveUsername(String username) async {
    await _storage.write(key: _usernameKey, value: username);
  }

  Future<String?> getSavedUsername() async {
    return _storage.read(key: _usernameKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  Future<String?> getRole() async {
    return _storage.read(key: _roleKey);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // ─────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────
  Map<String, dynamic>? _tryDecodeBody(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }
}

// ─────────────────────────────────────────────────────────
// RESULT CLASSES
// ─────────────────────────────────────────────────────────

class AuthResult {
  final bool    isSuccess;
  final String? errorMessage;

  AuthResult._({required this.isSuccess, this.errorMessage});

  factory AuthResult.success() =>
      AuthResult._(isSuccess: true);

  factory AuthResult.failure(String message) =>
      AuthResult._(isSuccess: false, errorMessage: message);
}

class LoginResult {
  final bool         isSuccess;
  final JwtResponse? jwt;
  final String?      errorMessage;

  LoginResult._({required this.isSuccess, this.jwt, this.errorMessage});

  factory LoginResult.success(JwtResponse jwt) =>
      LoginResult._(isSuccess: true, jwt: jwt);

  factory LoginResult.failure(String message) =>
      LoginResult._(isSuccess: false, errorMessage: message);
}