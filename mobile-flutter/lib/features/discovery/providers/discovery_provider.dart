import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
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

  DiscoveryNotifier(this._dio) : super(const DiscoveryState()) {
    loadCandidates();
  }

  Future<void> loadCandidates() async {
    state = state.copyWith(candidates: state.candidates, isLoading: true);

    try {
      final response = await _dio.get(ApiEndpoints.potentialMatches);
      if (response.data is List) {
        final list = (response.data as List)
            .map((item) => MatchProfile.fromJson(item))
            .toList();
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
    }).catchError((_) {});

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
    }).catchError((_) {});

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
  return DiscoveryNotifier(dio);
});
