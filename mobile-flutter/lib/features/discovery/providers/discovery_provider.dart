import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/models/user_model.dart';
import '../models/match_profile.dart';

class DiscoveryState {
  final List<MatchProfile> candidates;
  final bool isLoading;
  final String? errorMessage;
  final MatchProfile? matchedCandidate;
  final int viewsToday;
  final int dailyLimit;
  final bool hasExceededLimit;
  final String? limitNoticeMessage;

  const DiscoveryState({
    this.candidates = const [],
    this.isLoading = false,
    this.errorMessage,
    this.matchedCandidate,
    this.viewsToday = 0,
    this.dailyLimit = 3,
    this.hasExceededLimit = false,
    this.limitNoticeMessage,
  });

  int get remainingDailyViews => (dailyLimit - viewsToday).clamp(0, dailyLimit);

  DiscoveryState copyWith({
    List<MatchProfile>? candidates,
    bool? isLoading,
    String? errorMessage,
    MatchProfile? matchedCandidate,
    int? viewsToday,
    int? dailyLimit,
    bool? hasExceededLimit,
    String? limitNoticeMessage,
    bool clearNotice = false,
  }) {
    return DiscoveryState(
      candidates: candidates ?? this.candidates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      matchedCandidate: matchedCandidate,
      viewsToday: viewsToday ?? this.viewsToday,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      hasExceededLimit: hasExceededLimit ?? this.hasExceededLimit,
      limitNoticeMessage: clearNotice ? null : (limitNoticeMessage ?? this.limitNoticeMessage),
    );
  }
}

class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final Dio _dio;
  final Ref _ref;

  DiscoveryNotifier(this._dio, this._ref) : super(const DiscoveryState()) {
    initLimitsAndLoad();
  }

  int _calculateTierLimit(UserModel? user) {
    if (user == null) return 3;
    final tier = (user.subscriptionTier).trim().toLowerCase();
    if (tier.contains('executive')) return 100;
    if (tier.contains('elite')) return 25;
    if (tier.contains('premium') || user.isPremium) return 15;
    return 3; // Essential / Free
  }

  Future<void> initLimitsAndLoad() async {
    final storage = _ref.read(secureStorageProvider);
    final count = await storage.getDailyViewCount();
    final authState = _ref.read(authProvider);
    final limit = _calculateTierLimit(authState.user);
    final isExceeded = count >= limit;

    state = state.copyWith(
      viewsToday: count,
      dailyLimit: limit,
      hasExceededLimit: isExceeded,
    );

    await loadCandidates();
  }

  static bool isMale(String? g) {
    if (g == null) return false;
    final s = g.trim().toLowerCase();
    return s == 'male' || s == 'man' || s == 'm' || s == 'gentleman' || s == 'he' || s == 'he/him' || s == 'boy';
  }

  static bool isFemale(String? g) {
    if (g == null) return false;
    final s = g.trim().toLowerCase();
    return s == 'female' || s == 'woman' || s == 'f' || s == 'lady' || s == 'she' || s == 'she/her' || s == 'girl';
  }

  static List<MatchProfile> filterOppositeGender({
    required List<MatchProfile> candidates,
    required UserModel? currentUser,
  }) {
    if (currentUser == null) {
      return candidates;
    }

    final currentUserId = currentUser.id.trim();
    final currentUserFullName = currentUser.fullName.trim().toLowerCase();
    final userFirstName = currentUser.firstName.trim().toLowerCase();
    final userLastName = currentUser.lastName.trim().toLowerCase();

    // 1. Determine current user's gender
    bool userIsMale = isMale(currentUser.gender);
    bool userIsFemale = isFemale(currentUser.gender);

    // If gender wasn't explicit, check preferredGender:
    // User who prefers female is seeking female candidates (user is Male)
    // User who prefers male is seeking male candidates (user is Female)
    if (!userIsMale && !userIsFemale) {
      if (isFemale(currentUser.preferredGender)) {
        userIsMale = true;
      } else if (isMale(currentUser.preferredGender)) {
        userIsFemale = true;
      }
    }

    // Name inference for user if gender not set
    if (!userIsMale && !userIsFemale) {
      final name = userFirstName.isNotEmpty ? userFirstName : currentUserFullName.split(' ').first;
      const maleNames = ['michael', 'alex', 'david', 'john', 'james', 'daniel', 'liam', 'chen'];
      const femaleNames = ['sarah', 'emily', 'sophia', 'zainab', 'priya', 'amina', 'chloe'];
      if (maleNames.contains(name)) userIsMale = true;
      if (femaleNames.contains(name)) userIsFemale = true;
    }

    return candidates.where((c) {
      // 1. Never match user to themselves
      if (currentUserId.isNotEmpty && c.id == currentUserId) return false;
      final candName = c.name.trim().toLowerCase();
      if (currentUserFullName.isNotEmpty && candName.isNotEmpty && candName == currentUserFullName) {
        return false;
      }
      if (userFirstName.isNotEmpty && userLastName.isNotEmpty && candName.isNotEmpty) {
        if (candName.contains(userFirstName) && candName.contains(userLastName)) {
          return false;
        }
      }

      // 2. Strict Opposite-Gender Enforcement
      final cGen = c.gender.trim().toLowerCase();
      final candIsMale = isMale(cGen);
      final candIsFemale = isFemale(cGen);

      if (userIsMale) {
        // Male user must ONLY see female candidates! Strictly forbid male candidates.
        return candIsFemale && !candIsMale;
      } else if (userIsFemale) {
        // Female user must ONLY see male candidates! Strictly forbid female candidates.
        return candIsMale && !candIsFemale;
      }

      // Fallback: If current user's gender couldn't be resolved, forbid candidates of identical detected gender
      if (cGen.isNotEmpty && currentUser.gender.trim().toLowerCase() == cGen) {
        return false;
      }

      return true;
    }).toList();
  }

  Future<void> loadCandidates() async {
    state = state.copyWith(candidates: state.candidates, isLoading: true);

    try {
      final response = await _dio.get(ApiEndpoints.potentialMatches);
      if (response.data is List) {
        var list = (response.data as List)
            .map((item) => MatchProfile.fromJson(item))
            .toList();

        final authState = _ref.read(authProvider);
        list = filterOppositeGender(
          candidates: list,
          currentUser: authState.user,
        );

        state = state.copyWith(candidates: list, isLoading: false);
        return;
      }
    } catch (_) {
      // API error or empty state
    }

    state = state.copyWith(
      candidates: const [],
      isLoading: false,
    );
  }

  Future<String?> _checkAndGetDailyNotice(UserModel? user, int limit, int currentCount) async {
    final storage = _ref.read(secureStorageProvider);
    final hasSeenToday = await storage.hasSeenUpgradeReminderToday();
    if (hasSeenToday) {
      return null;
    }

    // 1. Check daily view limit reached
    if (currentCount >= limit) {
      await storage.markUpgradeReminderSeenToday();

      final tier = user?.subscriptionTier.trim().toLowerCase() ?? 'essential';
      if (tier.contains('executive')) {
        return "You've reviewed your 100 daily Executive matches. Your curated deck refreshes at midnight.";
      } else if (tier.contains('elite')) {
        return "You've completed your 25 daily Elite matches. Upgrade to Executive for 100 verified candidates daily.";
      } else if (tier.contains('premium') || (user?.isPremium ?? false)) {
        return "You've completed your 15 daily Premium matches. Upgrade to Elite or Executive for 25 to 100 candidates daily.";
      } else {
        return "You've reviewed your $limit daily matches. Upgrade your tier to unlock 15+ verified candidates daily.";
      }
    }

    return null;
  }

  Future<void> likeCandidate(MatchProfile candidate) async {
    final storage = _ref.read(secureStorageProvider);
    final authState = _ref.read(authProvider);
    final limit = _calculateTierLimit(authState.user);

    // Send like action to backend
    _dio.post(ApiEndpoints.matchAction, data: {
      'partnerId': candidate.id,
      'action': 'like',
    }).then((_) {}, onError: (_) {});

    final nextCount = await storage.incrementDailyViewCount();
    final reachedOrExceeded = nextCount >= limit;
    final noticeMsg = await _checkAndGetDailyNotice(authState.user, limit, nextCount);

    state = state.copyWith(
      matchedCandidate: candidate,
      viewsToday: nextCount,
      dailyLimit: limit,
      hasExceededLimit: reachedOrExceeded,
      limitNoticeMessage: noticeMsg,
    );
  }

  Future<void> passCandidate(MatchProfile candidate) async {
    final storage = _ref.read(secureStorageProvider);
    final authState = _ref.read(authProvider);
    final limit = _calculateTierLimit(authState.user);

    // Send pass action to backend
    _dio.post(ApiEndpoints.matchAction, data: {
      'partnerId': candidate.id,
      'action': 'pass',
    }).then((_) {}, onError: (_) {});

    final nextCount = await storage.incrementDailyViewCount();
    final reachedOrExceeded = nextCount >= limit;
    final noticeMsg = await _checkAndGetDailyNotice(authState.user, limit, nextCount);

    state = state.copyWith(
      viewsToday: nextCount,
      dailyLimit: limit,
      hasExceededLimit: reachedOrExceeded,
      limitNoticeMessage: noticeMsg,
    );
  }

  void onDeckEmpty() {
    // Keep candidates accessible for continuous looping review
  }

  void clearLimitNotice() {
    state = state.copyWith(clearNotice: true);
  }

  void dismissMatchModal() {
    state = state.copyWith(
      matchedCandidate: null,
    );
  }
}

final discoveryProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final dio = ref.watch(dioProvider);
  return DiscoveryNotifier(dio, ref);
});
