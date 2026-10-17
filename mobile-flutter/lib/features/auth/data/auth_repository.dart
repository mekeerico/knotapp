import 'package:dio/dio.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final Dio _dio;
  final SecureStorageService _storage;

  AuthRepository(this._dio, this._storage);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.login,
        data: {'email': email.trim(), 'password': password},
      );

      final token = response.data['token'] ?? response.data['accessToken'];
      if (token != null) {
        await _storage.saveToken(token.toString());
      }

      final userData = response.data['user'] ?? response.data;
      final user = UserModel.fromJson(userData);
      await _storage.saveUserId(user.id);
      return user;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message ?? 'Login failed';
        throw Exception(message);
      }
      throw Exception('Login failed: $e');
    }
  }

  Future<UserModel> register(String email, String password) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.register,
        data: {'email': email.trim(), 'password': password},
      );

      final token = response.data['token'] ?? response.data['accessToken'];
      if (token != null) {
        await _storage.saveToken(token.toString());
      }

      final userData = response.data['user'] ?? response.data;
      final user = UserModel.fromJson(userData);
      await _storage.saveUserId(user.id);
      return user;
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message ?? 'Registration failed';
        throw Exception(message);
      }
      throw Exception('Registration failed: $e');
    }
  }

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.profile);
      return UserModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message ?? 'Failed to load profile';
        throw Exception(message);
      }
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<UserModel> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      final response = await _dio.put(
        '${ApiEndpoints.updateProfile}/$userId',
        data: data,
      );
      return UserModel.fromJson(response.data);
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data?['message'] ?? e.message ?? 'Update failed';
        throw Exception(message);
      }
      throw Exception('Update failed: $e');
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
}
