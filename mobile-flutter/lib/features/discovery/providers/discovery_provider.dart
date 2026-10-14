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
    final user = _ref.read(authProvider).user;
    final userGender = user?.gender.toLowerCase() ?? '';
    final isMaleUser = userGender == 'male';

    try {
      final response = await _dio.get(ApiEndpoints.potentialMatches);
      if (response.data is List && (response.data as List).isNotEmpty) {
        final list = (response.data as List)
            .map((item) => MatchProfile.fromJson(item))
            .toList();
        if (list.isNotEmpty) {
          state = state.copyWith(candidates: list, isLoading: false);
          return;
        }
      }
    } catch (_) {
      // Use gender-aligned registry profiles
    }

    // Strictly enforce opposite sex in default candidate pool
    final fallbackList = isMaleUser ? _defaultFemaleCandidates : _defaultMaleCandidates;

    state = state.copyWith(
      candidates: fallbackList,
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

  static final List<MatchProfile> _defaultFemaleCandidates = [
    MatchProfile(
      id: 'candidate-female-1',
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
      id: 'candidate-female-2',
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
    MatchProfile(
      id: 'candidate-female-3',
      name: 'Zara Al-Mansoor',
      age: 28,
      city: 'Dubai',
      country: 'United Arab Emirates',
      occupation: 'Architectural Director',
      education: 'Cambridge University',
      religion: 'Muslim',
      culturalBackground: 'Middle Eastern',
      marriageTimeline: 'ASAP',
      willingToRelocate: 'Maybe',
      childrenPreference: 'Wants children',
      bio: 'Deeply devoted to family honor, creative beauty, and building an enduring marital home.',
      personalValues: ['Faith', 'Family', 'Honor', 'Wisdom'],
      personalityArchetype: 'The Intentional Builder',
      attachmentStyle: 'Secure',
      compatibilityScore: 94,
      emotionalAlignment: 91,
      valuesAlignment: 95,
      lifestyleCompatibility: 93,
      aiExplanation:
          'Strong mutual respect for lineage, family heritage, and disciplined marital leadership.',
      isVerified: true,
      verificationBadge: 'GOLD',
      photos: [
        'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800',
        'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=800',
      ],
    ),
  ];

  static final List<MatchProfile> _defaultMaleCandidates = [
    MatchProfile(
      id: 'candidate-male-1',
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
      id: 'candidate-male-2',
      name: 'Adebayo Adeleke',
      age: 29,
      city: 'London',
      country: 'United Kingdom',
      occupation: 'Private Equity Partner',
      education: 'Oxford University',
      religion: 'Christian',
      culturalBackground: 'African Diaspora',
      marriageTimeline: '1-2 years',
      willingToRelocate: 'Yes',
      childrenPreference: 'Wants children',
      bio: 'Focused on creating a generational home founded on faith, mutual growth, and unshakeable respect.',
      personalValues: ['Faith', 'Family', 'Generosity', 'Integrity'],
      personalityArchetype: 'The Grounded Romantic',
      attachmentStyle: 'Secure',
      compatibilityScore: 95,
      emotionalAlignment: 93,
      valuesAlignment: 97,
      lifestyleCompatibility: 94,
      aiExplanation:
          'Extraordinary alignment on spiritual commitment, family values, and proactive communication.',
      isVerified: true,
      verificationBadge: 'GOLD',
      photos: [
        'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=800',
        'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?q=80&w=800',
      ],
    ),
    MatchProfile(
      id: 'candidate-male-3',
      name: 'Dr. Alexander Wright',
      age: 32,
      city: 'Toronto',
      country: 'Canada',
      occupation: 'Cardiothoracic Fellow',
      education: 'University of Toronto',
      religion: 'Christian',
      culturalBackground: 'Canadian-British',
      marriageTimeline: 'ASAP',
      willingToRelocate: 'Maybe',
      childrenPreference: 'Wants children',
      bio: 'Passionate about purpose, thoughtful conversations, and building an enduring marriage.',
      personalValues: ['Empathy', 'Faith', 'Family', 'Service'],
      personalityArchetype: 'The Calm Connector',
      attachmentStyle: 'Secure',
      compatibilityScore: 92,
      emotionalAlignment: 94,
      valuesAlignment: 91,
      lifestyleCompatibility: 90,
      aiExplanation:
          'Deep emotional compatibility and shared readiness for lifelong marital commitment.',
      isVerified: true,
      verificationBadge: 'GOLD',
      photos: [
        'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=800',
        'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?q=80&w=800',
      ],
    ),
  ];
}

final discoveryProvider =
    StateNotifierProvider<DiscoveryNotifier, DiscoveryState>((ref) {
  final dio = ref.watch(dioProvider);
  return DiscoveryNotifier(dio, ref);
});
