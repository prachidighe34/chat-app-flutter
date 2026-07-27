import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

class AuthService {
  // web uses different storage options
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(dbName: 'chatApp', publicKey: 'chatAppKey'),
  );

  static const String _accessTokenKey = 'accessToken';
  static const String _refreshTokenKey = 'refreshToken';
  static const String _userKey = 'user';

  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
  }

  static Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  static Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: _userKey);
  }

  static Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<String?> refreshAccessToken(String baseUrl) async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return null;

      final dio = Dio();
      final response = await dio.post(
        '$baseUrl/refresh-token',
        data: {'refreshToken': refreshToken},
      );

      if (response.data['success'] == true) {
        final newAccessToken = response.data['accessToken'];
        await _storage.write(key: _accessTokenKey, value: newAccessToken);
        return newAccessToken;
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
