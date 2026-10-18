import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_image.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../models/match_profile.dart';
import '../providers/discovery_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/candidate_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final CardSwiperController _swiperController = CardSwiperController();

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);
    final notifier = ref.read(discoveryProvider.notifier);

    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        showLogo: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.champagneGold),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Registry filters active: Verified Candidates (18+).')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.champagneGold),
                    ),
                  )
                : state.candidates.isEmpty
                    ? _buildEmptyRegistry(notifier, authState.user?.gender)
                    : Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: CardSwiper(
                                key: ValueKey('deck_${state.candidates.length}'),
                                controller: _swiperController,
                                cardsCount: state.candidates.length,
                                numberOfCardsDisplayed: 1,
                                backCardOffset: Offset.zero,
                                isLoop: false,
                                onEnd: () {
                                  notifier.onDeckEmpty();
                                },
                                cardBuilder: (context, index, percentX, percentY) {
                                  if (index < 0 || index >= state.candidates.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final candidate = state.candidates[index];
                                  return CandidateCard(
                                    candidate: candidate,
                                    onDetailsTap: () {
                                      context.push('/profile-detail', extra: candidate);
                                    },
                                  );
                                },
                                onSwipe: (previousIndex, currentIndex, direction) {
                                  if (previousIndex >= 0 && previousIndex < state.candidates.length) {
                                    final candidate = state.candidates[previousIndex];
                                    if (direction == CardSwiperDirection.right) {
                                      notifier.likeCandidate(candidate);
                                    } else {
                                      notifier.passCandidate(candidate);
                                    }
                                  }
                                  return true;
                                },
                                padding: EdgeInsets.zero,
                              ),
                            ),
                          ),

                          // Action Buttons Bar
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16, top: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Pass Button (X)
                                _buildActionButton(
                                  icon: Icons.close,
                                  color: AppColors.textSubtle,
                                  onTap: () {
                                    if (state.candidates.isNotEmpty) {
                                      _swiperController.swipe(CardSwiperDirection.left);
                                    }
                                  },
                                ),
                                const SizedBox(width: 24),

                                // View Details & Compatibility Button
                                _buildActionButton(
                                  icon: Icons.star,
                                  color: AppColors.champagneGold,
                                  size: 64,
                                  onTap: () {
                                    if (state.candidates.isNotEmpty) {
                                      context.push('/profile-detail', extra: state.candidates.first);
                                    }
                                  },
                                ),
                                const SizedBox(width: 24),

                                // Like & Connect Button (Red Heart)
                                _buildActionButton(
                                  icon: Icons.favorite,
                                  color: AppColors.roseGlow,
                                  onTap: () {
                                    if (state.candidates.isNotEmpty) {
                                      notifier.likeCandidate(state.candidates.first);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

            // Celebratory Match Modal Overlay
            if (state.matchedCandidate != null)
              _buildMatchCelebrationModal(context, state.matchedCandidate!, notifier),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 52,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkSlate,
          border: Border.all(color: color.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.45),
      ),
    );
  }

  Widget _buildEmptyRegistry(DiscoveryNotifier notifier, String? userGender) {
    final gender = userGender?.trim().toLowerCase() ?? '';
    final targetCohort = gender == 'male'
        ? 'eligible ladies'
        : (gender == 'female' ? 'eligible gentlemen' : 'verified candidates');

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.champagneGold.withOpacity(0.12),
                  border: Border.all(color: AppColors.champagneGold.withOpacity(0.4), width: 1.5),
                ),
                child: const Icon(Icons.explore_outlined, size: 36, color: AppColors.champagneGold),
              ),
              const SizedBox(height: 22),
              Text(
                'Curating Sovereign Matches',
                style: AppTypography.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'The Knot Registry is actively scanning for verified $targetCohort who align with your matrimonial values and marital vision.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.darkSlate.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, size: 16, color: AppColors.champagneGold),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'New profiles appear immediately upon biometric onboarding.',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GoldButton(
                text: 'Check for New Candidates',
                onPressed: () => notifier.loadCandidates(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCelebrationModal(
    BuildContext context,
    MatchProfile candidate,
    DiscoveryNotifier notifier,
  ) {
    final photo = candidate.photos.isNotEmpty ? candidate.photos.first : '';

    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.85),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.champagneGold, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.roseGlow.withOpacity(0.35),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      child: KnotImage(
                        imageUrl: photo,
                        width: 96,
                        height: 96,
                        isCircle: true,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.obsidianBlack,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.favorite, size: 20, color: AppColors.roseGlow),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text('MUTUAL ALIGNMENT', style: AppTypography.displayMedium.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  'You and ${candidate.name} share ${candidate.compatibilityScore}% verified compatibility.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GoldButton(
                  text: 'View Full Profile & Details',
                  onPressed: () {
                    notifier.dismissMatchModal();
                    context.push('/profile-detail', extra: candidate);
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    side: const BorderSide(color: AppColors.borderGold),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                  onPressed: () {
                    final id = candidate.id;
                    notifier.dismissMatchModal();
                    context.push('/chat/$id', extra: candidate);
                  },
                  child: Text('Open Conversation', style: AppTypography.button.copyWith(color: AppColors.champagneGold)),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => notifier.dismissMatchModal(),
                  child: Text('Keep Discovering', style: AppTypography.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
