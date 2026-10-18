import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String tokenKey = 'knot_token';
  static const String userIdKey = 'knot_user_id';
  static const String hasSeenWelcomeKey = 'knot_has_seen_welcome';
  static const String savedEmailKey = 'knot_saved_email';
  static const String savedPasswordKey = 'knot_saved_password';
  static const String rememberMeKey = 'knot_remember_me';

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

  Future<void> markWelcomeSeen() async {
    await _storage.write(key: hasSeenWelcomeKey, value: 'true');
  }

  Future<bool> hasSeenWelcome() async {
    final val = await _storage.read(key: hasSeenWelcomeKey);
    return val == 'true';
  }

  Future<void> saveCredentials(String email, String password) async {
    await _storage.write(key: savedEmailKey, value: email);
    await _storage.write(key: savedPasswordKey, value: password);
    await _storage.write(key: rememberMeKey, value: 'true');
  }

  Future<String?> getSavedEmail() async {
    return await _storage.read(key: savedEmailKey);
  }

  Future<String?> getSavedPassword() async {
    return await _storage.read(key: savedPasswordKey);
  }

  Future<void> setRememberMe(bool remember) async {
    await _storage.write(key: rememberMeKey, value: remember ? 'true' : 'false');
    if (!remember) {
      await clearSavedCredentials();
    }
  }

  Future<bool> getRememberMe() async {
    final val = await _storage.read(key: rememberMeKey);
    // Default to true so credentials are remembered by default
    return val == null || val == 'true';
  }

  Future<void> clearSavedCredentials() async {
    await _storage.delete(key: savedEmailKey);
    await _storage.delete(key: savedPasswordKey);
  }

  Future<void> clearAll() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: userIdKey);
  }
}
