import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../data/auth_repository.dart';
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  final storage = ref.watch(secureStorageProvider);
  return AuthRepository(dio, storage);
});

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class InitialAuthState {
  final bool hasSeenWelcome;
  final bool hasToken;

  const InitialAuthState({
    this.hasSeenWelcome = false,
    this.hasToken = false,
  });
}

final initialAuthStateProvider = Provider<InitialAuthState>((ref) {
  return const InitialAuthState();
});

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;
  final bool hasSeenWelcome;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
    this.hasSeenWelcome = false,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get needsOnboarding =>
      isAuthenticated && (user?.firstName.isEmpty ?? true);
  bool get isVerified => user?.isVerified ?? false;

  AuthState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
    bool? hasSeenWelcome,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
      hasSeenWelcome: hasSeenWelcome ?? this.hasSeenWelcome,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo, InitialAuthState initial)
      : super(AuthState(
          status: initial.hasToken
              ? AuthStatus.loading
              : (initial.hasSeenWelcome
                  ? AuthStatus.unauthenticated
                  : AuthStatus.initial),
          hasSeenWelcome: initial.hasSeenWelcome,
        )) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    state = state.copyWith(status: AuthStatus.loading);
    final seenWelcome = await _repo.hasSeenWelcome();
    try {
      final user = await _repo.getProfile();
      await _repo.markWelcomeSeen();
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasSeenWelcome: true,
      );
      RevenueCatService.logIn(user.id);
    } catch (_) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        user: null,
        hasSeenWelcome: seenWelcome,
      );
    }
  }

  Future<void> completeWelcome() async {
    await _repo.markWelcomeSeen();
    state = state.copyWith(hasSeenWelcome: true);
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.login(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasSeenWelcome: true,
      );
      _repo.markWelcomeSeen();
      RevenueCatService.logIn(user.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    state = state.copyWith(status: AuthStatus.loading, errorMessage: null);
    try {
      final user = await _repo.register(email, password);
      state = state.copyWith(
        status: AuthStatus.authenticated,
        user: user,
        hasSeenWelcome: true,
      );
      _repo.markWelcomeSeen();
      RevenueCatService.logIn(user.id);
      return true;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (state.user == null) return;
    try {
      final updated = await _repo.updateProfile(state.user!.id, data);
      state = state.copyWith(user: updated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }

  void setUser(UserModel user) {
    state = state.copyWith(
      status: AuthStatus.authenticated,
      user: user,
      hasSeenWelcome: true,
    );
    RevenueCatService.logIn(user.id);
  }

  Future<void> logout() async {
    await _repo.logout();
    await RevenueCatService.logOut();
    state = const AuthState(
      status: AuthStatus.unauthenticated,
      hasSeenWelcome: true,
    );
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  final initial = ref.watch(initialAuthStateProvider);
  return AuthNotifier(repo, initial);
});
