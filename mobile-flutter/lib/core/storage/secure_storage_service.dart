import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String tokenKey = 'knot_token';
  static const String userIdKey = 'knot_user_id';

  final FlutterSecureStorage _storage;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: tokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: userIdKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}
