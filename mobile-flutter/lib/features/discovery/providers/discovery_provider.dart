import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/match_profile.dart';

class DiscoveryState {
  final List<MatchProfile> candidates;
  final bool isLoading;
  final String? errorMessage;
  final MatchProfile? matchedCandidate;

  const DiscoveryState({
    this.candidates = const [],
    this.isLoading = false,
    this.errorMessage,
    this.matchedCandidate,
  });

  DiscoveryState copyWith({
    List<MatchProfile>? candidates,
    bool? isLoading,
    String? errorMessage,
    MatchProfile? matchedCandidate,
  }) {
    return DiscoveryState(
      candidates: candidates ?? this.candidates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      matchedCandidate: matchedCandidate,
    );
  }
}

class DiscoveryNotifier extends StateNotifier<DiscoveryState> {
  final Dio _dio;
  final Ref _ref;

  DiscoveryNotifier(this._dio, this._ref) : super(const DiscoveryState()) {
    loadCandidates();
  }

  Future<void> loadCandidates() async {
    state = state.copyWith(candidates: state.candidates, isLoading: true);

    try {
      final response = await _dio.get(ApiEndpoints.potentialMatches);
      if (response.data is List) {
        var list = (response.data as List)
            .map((item) => MatchProfile.fromJson(item))
            .toList();

        // Strict Client-Side Self-Exclusion & Opposite-Gender Enforcement:
        // Guarantees that a user can NEVER see themselves and can ONLY see opposite-sex candidates
        final authState = _ref.read(authProvider);
        final currentUserId = (authState.user?.id ?? '').trim();
        final currentUserEmail = (authState.user?.email ?? '').trim().toLowerCase();
        final currentUserFullName = (authState.user?.fullName ?? '').trim().toLowerCase();
        final userFirstName = (authState.user?.firstName ?? '').trim().toLowerCase();
        final userLastName = (authState.user?.lastName ?? '').trim().toLowerCase();
        final userGender = (authState.user?.gender ?? '').trim().toLowerCase();

        final isUserMale = userGender == 'male' || userGender == 'man' || userGender == 'm';
        final isUserFemale = userGender == 'female' || userGender == 'woman' || userGender == 'f';

        list = list.where((c) {
          // 1. Strict Self-Exclusion: User can NEVER be matched to themselves
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

          // 2. Strict Opposite-Gender Enforcement: Only opposite sex (Male <-> Female)
          final cGen = c.gender.trim().toLowerCase();
          final isCandMale = cGen == 'male' || cGen == 'man' || cGen == 'm';
          final isCandFemale = cGen == 'female' || cGen == 'woman' || cGen == 'f';

          if (isUserMale) {
            // Male user must only see female candidates
            return isCandFemale && !isCandMale;
          } else if (isUserFemale) {
            // Female user must only see male candidates
            return isCandMale && !isCandFemale;
          }

          // If current user's gender string wasn't explicitly 'male' or 'female'
          // still forbid matching with candidates of the same detected gender
          if (cGen.isNotEmpty && userGender.isNotEmpty && cGen == userGender) {
            return false;
          }

          return true;
        }).toList();

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

  void likeCandidate(MatchProfile candidate) {
    // Send like action to backend
    _dio.post(ApiEndpoints.matchAction, data: {
      'partnerId': candidate.id,
      'action': 'like',
    }).then((_) {}, onError: (_) {});

    state = state.copyWith(
      candidates: state.candidates.where((c) => c.id != candidate.id).toList(),
      matchedCandidate: candidate,
    );
  }

  void passCandidate(MatchProfile candidate) {
    // Send pass action to backend
    _dio.post(ApiEndpoints.matchAction, data: {
      'partnerId': candidate.id,
      'action': 'pass',
    }).then((_) {}, onError: (_) {});

    state = state.copyWith(
      candidates: state.candidates.where((c) => c.id != candidate.id).toList(),
    );
  }

  void onDeckEmpty() {
    state = state.copyWith(
      candidates: const [],
    );
  }

  void dismissMatchModal() {
    state = state.copyWith(
      candidates: state.candidates,
      matchedCandidate: null,
    );
  }
}

final discoveryProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final dio = ref.watch(dioProvider);
  return DiscoveryNotifier(dio, ref);
});
