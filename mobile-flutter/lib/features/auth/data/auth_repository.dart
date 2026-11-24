import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository(this._dio, this._storage);

  Map<String, dynamic> _asMap(dynamic data, String context) {
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    throw Exception('$context: Unexpected server response. Please try again.');
  }

  String _extractDioError(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map) {
      final msg = data['message'] ?? data['error'];
      if (msg is List && msg.isNotEmpty) {
        return msg.join(', ');
      }
      if (msg != null && msg.toString().trim().isNotEmpty) {
        return msg.toString();
      }
    }
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      return '$fallback (HTTP $statusCode)';
    }
    return e.message ?? fallback;
  }

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );

      final body = _asMap(response.data, 'Login failed');
      final token = body['token'] ?? body['accessToken'];
      final userData = _asMap(body['user'] ?? body, 'Login failed');
      final user = UserModel.fromJson(userData);

      await Future.wait([
        if (token != null) _storage.saveToken(token.toString()),
        _storage.saveUserId(user.id),
      ]);
      return user;
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Login failed'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> sendSignupOtp(String email, String password) async {
    try {
      await _dio.post(
        ApiEndpoints.sendOtp,
        data: {'email': email.trim(), 'password': password},
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Failed to send verification code'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> verifySignupOtp(String email, String code) async {
    try {
      await _dio.post(
        ApiEndpoints.verifyOtp,
        data: {'email': email.trim(), 'code': code.trim()},
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Invalid verification code'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<UserModel> register(String email, String password, {String? otpCode}) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {
          'email': email.trim(),
          'password': password,
          if (otpCode != null) 'otpCode': otpCode.trim(),
        },
      );

      final body = _asMap(response.data, 'Registration failed');
      final token = body['token'] ?? body['accessToken'];
      final userData = _asMap(body['user'] ?? body, 'Registration failed');
      final user = UserModel.fromJson(userData);

      await Future.wait([
        if (token != null) _storage.saveToken(token.toString()),
        _storage.saveUserId(user.id),
      ]);
      return user;
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Registration failed'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return UserModel.fromJson(_asMap(response.data, 'Failed to load profile'));
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Failed to load profile'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<UserModel> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.updateProfile}/$userId',
        data: data,
      );
      return UserModel.fromJson(_asMap(response.data, 'Update failed'));
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Update failed'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<bool> hasSeenWelcome() async {
    return await _storage.hasSeenWelcome();
  }

  Future<void> markWelcomeSeen() async {
    await _storage.markWelcomeSeen();
  }

  Future<void> logout() async {
    await _storage.markWelcomeSeen();
    await _storage.clearAll();
  }

  Future<String> requestPasswordReset(String email) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.forgotPassword,
        data: {'email': email.trim()},
      );
      if (response.data is Map && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'A 6-digit password reset code has been sent to your email.';
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Failed to send password reset code'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.resetPassword,
        data: {
          'email': email.trim(),
          'code': code.trim(),
          'newPassword': newPassword,
        },
      );
      if (response.data is Map && response.data['message'] != null) {
        return response.data['message'].toString();
      }
      return 'Your password has been reset successfully. You can now sign in.';
    } catch (e) {
      if (e is DioException) {
        throw Exception(_extractDioError(e, 'Failed to reset password'));
      }
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }
}
