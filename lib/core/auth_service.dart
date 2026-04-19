import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static String? _inMemoryToken;

  static String hashPassword(String password) {
    final input = 'lad-admin:$password';
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> saveToken(String token) async {
    _inMemoryToken = token;
  }

  static Future<String?> getToken() async {
    return _inMemoryToken;
  }

  static Future<void> logout() async {
    _inMemoryToken = null;
  }

  static Future<bool> isAuthenticated() async {
    return _inMemoryToken != null;
  }
}
