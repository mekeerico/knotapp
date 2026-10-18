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

        // Strict Client-Side Opposite-Gender Enforcement:
        // Ensures that under all network circumstances, candidates of the same gender are never shown
        final authState = _ref.read(authProvider);
        final userGender = (authState.user?.gender ?? '').trim().toLowerCase();
        if (userGender.isNotEmpty) {
          final isUserMale = userGender == 'male' || userGender == 'man' || userGender == 'm';
          final isUserFemale = userGender == 'female' || userGender == 'woman' || userGender == 'f';

          list = list.where((c) {
            final cGen = c.gender.trim().toLowerCase();
            if (cGen.isEmpty) return true;
            if (isUserMale) {
              return cGen != 'male' && cGen != 'man' && cGen != 'm';
            } else if (isUserFemale) {
              return cGen != 'female' && cGen != 'woman' && cGen != 'f';
            }
            return true;
          }).toList();
        }

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
