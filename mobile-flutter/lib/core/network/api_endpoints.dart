import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiEndpoints {
  // Configurable with --dart-define=API_URL=https://api.yourknot.com
  static const String _overrideUrl = String.fromEnvironment('API_URL');

  static String get baseUrl {
    if (_overrideUrl.isNotEmpty) {
      return _overrideUrl;
    }
    if (kIsWeb) {
      return 'http://knotconnect.duckdns.org:8080';
    }
    if (kReleaseMode) {
      return 'http://knotconnect.duckdns.org:8080';
    }
    if (Platform.isAndroid) {
      // Android emulator reaches host loopback via 10.0.2.2 in debug mode
      return 'http://10.0.2.2:8080';
    }
    // iOS simulator, macOS, Linux, Windows localhost
    return 'http://localhost:8080';
  }

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';

  // Users
  static const String profile = '/users/profile';
  static const String updateProfile = '/users';
  static const String verifyIdentity = '/users/verify-identity';
  static const String validateAnswer = '/users/onboarding/validate-answer';

  // Matches
  static const String potentialMatches = '/matches/potential';
  static const String matches = '/matches';
  static const String matchAction = '/matches/action';

  // Chat & Messages
  static const String messages = '/messages';

  // AI Coach & Compatibility
  static const String aiCoach = '/ai/coach';
  static const String aiCompatibility = '/ai/compatibility';

  // Payments & Subscriptions
  static const String initializePayment = '/payments/initialize';
  static const String verifyPayment = '/payments/verify';
}
