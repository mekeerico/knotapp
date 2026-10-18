import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const String tokenKey = 'knot_token';
  static const String userIdKey = 'knot_user_id';
  static const String hasSeenWelcomeKey = 'knot_has_seen_welcome';
  static const String savedEmailKey = 'knot_saved_email';
  static const String savedPasswordKey = 'knot_saved_password';
  static const String rememberMeKey = 'knot_remember_me';

  final FlutterSecureStorage _storage;
  String? _cachedToken;
  String? _cachedUserId;

  SecureStorageService()
      : _storage = const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _storage.read(key: tokenKey);
    return _cachedToken;
  }

  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _storage.write(key: userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    _cachedUserId = await _storage.read(key: userIdKey);
    return _cachedUserId;
  }

  Future<void> markWelcomeSeen() async {
    await _storage.write(key: hasSeenWelcomeKey, value: 'true');
  }

  Future<bool> hasSeenWelcome() async {
    final val = await _storage.read(key: hasSeenWelcomeKey);
    return val == 'true';
  }

  Future<void> saveCredentials(String email, String password) async {
    await Future.wait([
      _storage.write(key: savedEmailKey, value: email),
      _storage.write(key: savedPasswordKey, value: password),
      _storage.write(key: rememberMeKey, value: 'true'),
    ]);
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
    await Future.wait([
      _storage.delete(key: savedEmailKey),
      _storage.delete(key: savedPasswordKey),
    ]);
  }

  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedUserId = null;
    await Future.wait([
      _storage.delete(key: tokenKey),
      _storage.delete(key: userIdKey),
    ]);
  }
}
