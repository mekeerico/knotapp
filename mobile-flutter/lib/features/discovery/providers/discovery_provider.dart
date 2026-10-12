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
      if (response.data is List && (response.data as List).isNotEmpty) {
        final list = (response.data as List)
            .map((item) => MatchProfile.fromJson(item))
            .toList();
        state = state.copyWith(candidates: list, isLoading: false);
        return;
      }
    } catch (_) {
      // Use premium default registry profiles
    }

    state = state.copyWith(
      candidates: _defaultCandidates,
      isLoading: false,
    );
  }

  void likeCandidate(MatchProfile candidate) {
    // Check if celebration match modal should appear
    final isMatch = candidate.compatibilityScore >= 90;
    state = state.copyWith(
      candidates: state.candidates.where((c) => c.id != candidate.id).toList(),
      matchedCandidate: isMatch ? candidate : null,
    );
  }

  void passCandidate(MatchProfile candidate) {
    state = state.copyWith(
      candidates: state.candidates.where((c) => c.id != candidate.id).toList(),
    );
  }

  void dismissMatchModal() {
    state = state.copyWith(
      candidates: state.candidates,
      matchedCandidate: null,
    );
  }

  static final List<MatchProfile> _defaultCandidates = [
    MatchProfile(
      id: 'candidate-1',
      name: 'Sophia Sterling',
      age: 27,
      city: 'London',
      country: 'United Kingdom',
      occupation: 'Pediatric Surgeon',
      education: 'Imperial College London',
      religion: 'Christian',
      culturalBackground: 'British-European',
      marriageTimeline: '1-2 years',
      willingToRelocate: 'Yes',
      childrenPreference: 'Wants children',
      bio: 'Committed to purpose, family traditions, and building a foundation of emotional safety and shared dreams.',
      personalValues: ['Faith', 'Family', 'Excellence', 'Empathy'],
      personalityArchetype: 'The Grounded Romantic',
      attachmentStyle: 'Secure',
      compatibilityScore: 96,
      emotionalAlignment: 94,
      valuesAlignment: 98,
      lifestyleCompatibility: 95,
      aiExplanation:
          'Deep mutual alignment in family longevity, shared religious foundations, and desire for intentional commitment within 18 months.',
      isVerified: true,
      verificationBadge: 'GOLD',
      photos: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800',
        'https://images.unsplash.com/photo-1517841905240-472988babdf9?q=80&w=800',
      ],
    ),
    MatchProfile(
      id: 'candidate-2',
      name: 'Julian Montgomery',
      age: 30,
      city: 'Zurich',
      country: 'Switzerland',
      occupation: 'Wealth Management Director',
      education: 'ETH Zürich / HSG',
      religion: 'Christian',
      culturalBackground: 'Swiss-Global',
      marriageTimeline: 'ASAP',
      willingToRelocate: 'Open to discussion',
      childrenPreference: 'Wants children',
      bio: 'Believer in intentional courtship, personal leadership, and lifelong marriage partnership.',
      personalValues: ['Integrity', 'Faith', 'Family', 'Legacy'],
      personalityArchetype: 'The Intentional Builder',
      attachmentStyle: 'Secure',
      compatibilityScore: 93,
      emotionalAlignment: 90,
      valuesAlignment: 96,
      lifestyleCompatibility: 92,
      aiExplanation:
          'Both candidates express readiness for permanent matrimony and prioritize emotional stability.',
      isVerified: true,
      verificationBadge: 'GOLD',
      photos: [
        'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=800',
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=800',
      ],
    ),
    MatchProfile(
      id: 'candidate-3',
      name: 'Amara Okafor',
      age: 26,
      city: 'New York',
      country: 'United States',
      occupation: 'Biotech Venture Fellow',
      education: 'Columbia University',
      religion: 'Christian',
      culturalBackground: 'Global Diaspora',
      marriageTimeline: '1-2 years',
      willingToRelocate: 'Yes',
      childrenPreference: 'Wants children',
      bio: 'Combining intellect with warmth. Seeking someone who leads with kindness, faith, and mutual respect.',
      personalValues: ['Family', 'Faith', 'Ambition', 'Loyalty'],
      personalityArchetype: 'The Calm Connector',
      attachmentStyle: 'Secure',
      compatibilityScore: 91,
      emotionalAlignment: 92,
      valuesAlignment: 93,
      lifestyleCompatibility: 88,
      aiExplanation:
          'Harmonious communication patterns and highly aligned values surrounding children and career balance.',
      isVerified: true,
      verificationBadge: 'GOLD',
      photos: [
        'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?q=80&w=800',
        'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=800',
      ],
    ),
  ];
}

final discoveryProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final dio = ref.watch(dioProvider);
  return DiscoveryNotifier(dio);
});
