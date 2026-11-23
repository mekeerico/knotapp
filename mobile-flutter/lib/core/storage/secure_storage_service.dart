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
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
            resetOnError: true,
          ),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  FlutterSecureStorage get storage => _storage;

  Future<String?> _safeRead(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (_) {
      // Recover automatically from Android Keystore / Auto Backup AEADBadTagException
      try {
        await _storage.deleteAll();
      } catch (_) {}
      return null;
    }
  }

  Future<void> _safeWrite(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      try {
        await _storage.deleteAll();
        await _storage.write(key: key, value: value);
      } catch (_) {}
    }
  }

  Future<void> _safeDelete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {}
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _safeWrite(tokenKey, token);
  }

  Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    _cachedToken = await _safeRead(tokenKey);
    return _cachedToken;
  }

  Future<void> saveUserId(String userId) async {
    _cachedUserId = userId;
    await _safeWrite(userIdKey, userId);
  }

  Future<String?> getUserId() async {
    if (_cachedUserId != null) return _cachedUserId;
    _cachedUserId = await _safeRead(userIdKey);
    return _cachedUserId;
  }

  Future<void> markWelcomeSeen() async {
    await _safeWrite(hasSeenWelcomeKey, 'true');
  }

  Future<bool> hasSeenWelcome() async {
    final val = await _safeRead(hasSeenWelcomeKey);
    return val == 'true';
  }

  Future<void> saveCredentials(String email, String password) async {
    await Future.wait([
      _safeWrite(savedEmailKey, email),
      _safeWrite(savedPasswordKey, password),
      _safeWrite(rememberMeKey, 'true'),
    ]);
  }

  Future<String?> getSavedEmail() async {
    return await _safeRead(savedEmailKey);
  }

  Future<String?> getSavedPassword() async {
    return await _safeRead(savedPasswordKey);
  }

  Future<void> setRememberMe(bool remember) async {
    await _safeWrite(rememberMeKey, remember ? 'true' : 'false');
    if (!remember) {
      await clearSavedCredentials();
    }
  }

  Future<bool> getRememberMe() async {
    final val = await _safeRead(rememberMeKey);
    // Default to true so credentials are remembered by default
    return val == null || val == 'true';
  }

  Future<void> clearSavedCredentials() async {
    await Future.wait([
      _safeDelete(savedEmailKey),
      _safeDelete(savedPasswordKey),
    ]);
  }

  Future<void> clearAll() async {
    _cachedToken = null;
    _cachedUserId = null;
    await Future.wait([
      _safeDelete(tokenKey),
      _safeDelete(userIdKey),
    ]);
  }

  static const String dailyViewCountKey = 'knot_daily_view_count';
  static const String dailyViewDateKey = 'knot_daily_view_date';
  static const String lastUpgradeReminderDateKey = 'knot_last_upgrade_reminder_date';

  Future<bool> hasSeenUpgradeReminderToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = await _storage.read(key: lastUpgradeReminderDateKey);
    return lastDate == today;
  }

  Future<void> markUpgradeReminderSeenToday() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await _storage.write(key: lastUpgradeReminderDateKey, value: today);
  }

  Future<int> getDailyViewCount() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = await _storage.read(key: dailyViewDateKey);
    if (savedDate != today) {
      await _storage.write(key: dailyViewDateKey, value: today);
      await _storage.write(key: dailyViewCountKey, value: '0');
      return 0;
    }
    final countStr = await _storage.read(key: dailyViewCountKey);
    return int.tryParse(countStr ?? '0') ?? 0;
  }

  Future<int> incrementDailyViewCount() async {
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final current = await getDailyViewCount();
    final next = current + 1;
    await Future.wait([
      _storage.write(key: dailyViewDateKey, value: today),
      _storage.write(key: dailyViewCountKey, value: next.toString()),
    ]);
    return next;
  }
}
