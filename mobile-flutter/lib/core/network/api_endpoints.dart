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
      return 'https://knotmarriage.online/api-backend';
    }
    if (kReleaseMode) {
      return 'https://knotmarriage.online/api-backend';
    }
    if (Platform.isAndroid) {
      // Android emulator reaches host loopback via 10.0.2.2 in debug mode
      return 'http://10.0.2.2:8080';
    }
    // iOS simulator, macOS, Linux, Windows localhost
    return 'http://localhost:8080';
  }

  // Auth
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // Users
  static const String profile = '/users/profile';
  static const String updateProfile = '/users';
  static const String verifyIdentity = '/users/verify-identity';
  static const String validateAnswer = '/users/onboarding/validate-answer';
  static const String support = '/users/support';
  static const String mySupport = '/users/support/my';

  // Matches
  static const String potentialMatches = '/matches/potential';
  static const String matches = '/matches';
  static const String matchAction = '/matches/action';

  // Chat & Messages
  static const String messages = '/messages';

  // Notifications
  static const String notifications = '/notifications';

  // Admin
  static const String adminUsers = '/admin/users';
  static const String adminEnquiries = '/admin/enquiries';
  static const String adminSystemAlerts = '/notifications/admin/system-alerts';
  static const String adminTestAlert = '/notifications/admin/test-developer-alert';
  static const String adminTriggerReminders = '/notifications/admin/trigger-verification-reminders';
  static const String adminCheckPlayStore = '/notifications/admin/check-play-store';
  static const String adminAnnounceUpdate = '/notifications/admin/announce-app-update';

  // AI Coach & Compatibility
  static const String aiCoach = '/ai/coach';
  static const String aiCompatibility = '/ai/compatibility';

  // Payments & Subscriptions
  static const String initializePayment = '/payments/initialize';
  static const String verifyPayment = '/payments/verify';
}
