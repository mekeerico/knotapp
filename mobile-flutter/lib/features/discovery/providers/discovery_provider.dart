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
    this.isLoading = true,
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

  static const Set<String> _maleNames = {
    'michael', 'alex', 'david', 'john', 'james', 'daniel', 'liam', 'chen',
    'robert', 'william', 'joseph', 'charles', 'thomas', 'christopher', 'matthew',
    'anthony', 'mark', 'steven', 'paul', 'andrew', 'joshua', 'kevin', 'brian',
    'george', 'edward', 'jason', 'ryan', 'jacob', 'nicholas', 'eric', 'emeke',
    'jonathan', 'stephen', 'justin', 'brandon', 'benjamin', 'samuel', 'alexander',
    'patrick', 'jack', 'tyler', 'aaron', 'adam', 'nathan', 'henry', 'zachary',
    'peter', 'kyle', 'ethan', 'jeremy', 'christian', 'noah', 'sean', 'austin',
    'arthur', 'jesse', 'dylan', 'bryan', 'jordan', 'gabriel', 'logan', 'alan',
    'juan', 'vincent', 'louis', 'philip', 'bradley', 'mike', 'tunde', 'femi',
    'chidi', 'obi', 'kofi', 'kwame', 'ahmed', 'ali', 'hassan', 'omar', 'ibrahim', 'musa', 'ajajwjwjw'
  };

  static const Set<String> _femaleNames = {
    'sarah', 'emily', 'sophia', 'zainab', 'priya', 'amina', 'chloe', 'emma',
    'olivia', 'ava', 'isabella', 'mia', 'charlotte', 'amelia', 'harper', 'evelyn',
    'abigail', 'elizabeth', 'sofia', 'avery', 'ella', 'scarlett', 'grace',
    'victoria', 'riley', 'aria', 'lily', 'aubrey', 'zoey', 'penelope', 'layla',
    'lillian', 'nora', 'camila', 'hannah', 'mila', 'eleanor', 'maya', 'stella',
    'hazel', 'leah', 'violet', 'aurora', 'savannah', 'audrey', 'brooklyn',
    'claire', 'skylar', 'ellie', 'lucy', 'anna', 'caroline', 'nova', 'genesis',
    'emilia', 'kennedy', 'samantha', 'allison', 'madelyn', 'adeline', 'hailey',
    'elena', 'cora', 'vivian', 'natalie', 'zoe', 'katelyn', 'fatima', 'aisha',
    'maryam', 'khadija', 'nour', 'huda', 'yasmin', 'iman', 'asma', 'mariam',
    'amara', 'chioma', 'ngozi', 'ada', 'adaora', 'blessing', 'mercy', 'joy',
    'chiamaka', 'yetunde', 'folake', 'funke'
  };

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

  static bool isMaleName(String? name) {
    if (name == null || name.isEmpty) return false;
    final first = name.trim().toLowerCase().split(RegExp(r'\s+')).first;
    return _maleNames.contains(first);
  }

  static bool isFemaleName(String? name) {
    if (name == null || name.isEmpty) return false;
    final first = name.trim().toLowerCase().split(RegExp(r'\s+')).first;
    return _femaleNames.contains(first);
  }

  static List<MatchProfile> filterOppositeGender({
    required List<MatchProfile> candidates,
    required UserModel? currentUser,
  }) {
    if (candidates.isEmpty) return const [];
    if (currentUser == null) {
      // If user profile has not loaded yet, do not leak or flash candidates
      return const [];
    }

    final currentUserId = currentUser.id.trim();
    final currentUserEmail = currentUser.email.trim().toLowerCase();
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

    // Name-based inference for user if gender not set
    if (!userIsMale && !userIsFemale) {
      final name = userFirstName.isNotEmpty ? userFirstName : currentUserFullName.split(' ').first;
      if (isMaleName(name)) userIsMale = true;
      if (isFemaleName(name)) userIsFemale = true;
    }

    // Email-based inference for user if gender not set
    if (!userIsMale && !userIsFemale && currentUserEmail.isNotEmpty) {
      final emailPrefix = currentUserEmail.split('@').first.toLowerCase();
      if (_maleNames.any((m) => emailPrefix.contains(m))) userIsMale = true;
      if (_femaleNames.any((f) => emailPrefix.contains(f))) userIsFemale = true;
    }

    // Deterministic fallback: default to male (seeking female) if still completely unresolved
    if (!userIsMale && !userIsFemale) {
      userIsMale = true;
    }

    final bool seekingFemale = userIsMale;

    return candidates.where((c) {
      // 1. Strict self-exclusion: User must NEVER be matched to themselves
      if (currentUserId.isNotEmpty && c.id == currentUserId) return false;
      if (currentUserEmail.isNotEmpty && c.id == currentUserEmail) return false;
      final candName = c.name.trim().toLowerCase();
      if (currentUserFullName.isNotEmpty && candName.isNotEmpty && candName == currentUserFullName) {
        return false;
      }
      if (userFirstName.isNotEmpty && userLastName.isNotEmpty && candName.isNotEmpty) {
        if (candName.contains(userFirstName) && candName.contains(userLastName)) {
          return false;
        }
      }

      // 2. Strict Opposite-Gender Enforcement: Only verified opposite gender candidates
      final cGen = c.gender.trim().toLowerCase();
      final candIsMale = isMale(cGen) || isMaleName(candName);
      final candIsFemale = isFemale(cGen) || isFemaleName(candName);

      if (seekingFemale) {
        // User seeking female: Candidate MUST be confirmed female, and MUST NOT be male
        if (candIsFemale && !candIsMale) {
          return true;
        }
        return false;
      } else {
        // User seeking male: Candidate MUST be confirmed male, and MUST NOT be female
        if (candIsMale && !candIsFemale) {
          return true;
        }
        return false;
      }
    }).toList();
  }

  Future<void> loadCandidates() async {
    state = state.copyWith(candidates: state.candidates, isLoading: true);

    try {
      final response = await _dio.get(ApiEndpoints.potentialMatches);
      if (response.data is List) {
        var list = (response.data as List)
            .map((item) => MatchProfile.fromJson(item))
            .where((c) {
              // Strictly real human candidates:
              // 1. Exclude test/mock seed accounts
              final idLower = c.id.toLowerCase();
              final nameLower = c.name.toLowerCase();
              if (idLower.contains('mock') || idLower.contains('dummy') || idLower.contains('test_')) {
                return false;
              }
              if (nameLower.contains('mock') || nameLower.contains('test user') || nameLower == 'candidate' || nameLower.contains('zainab') || nameLower.contains('balogun') || nameLower.contains('amara')) {
                return false;
              }
              // 2. Must have at least 1 real uploaded photo
              if (c.photos.isEmpty) {
                return false;
              }
              return true;
            })
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
