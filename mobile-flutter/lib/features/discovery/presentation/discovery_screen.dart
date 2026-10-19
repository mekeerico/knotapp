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
        showNotificationBell: true,
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
                    ? (state.hasExceededLimit
                        ? _buildDailyLimitReachedCard(context, state, notifier)
                        : _buildEmptyRegistry(notifier, authState.user?.gender))
                    : Column(
                        children: [
                          if (!(authState.user?.isPremium ?? false))
                            _buildFreeTierReminderPill(context, state, notifier),
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

            // First-Time / Exceeded Limit Upgrade Flier Modal
            if (state.showUpgradeFlier)
              _buildUpgradeFlierModal(context, state, notifier),
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

  Widget _buildFreeTierReminderPill(
    BuildContext context,
    DiscoveryState state,
    DiscoveryNotifier notifier,
  ) {
    final remaining = state.remainingDailyViews;
    final isOut = state.hasExceededLimit || remaining <= 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: () => context.push('/paywall'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.darkSlate,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isOut ? AppColors.roseGlow : AppColors.champagneGold.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: (isOut ? AppColors.roseGlow : AppColors.champagneGold).withOpacity(0.12),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOut ? Icons.lock_clock : Icons.stars_rounded,
                size: 15,
                color: isOut ? AppColors.roseGlow : AppColors.champagneGold,
              ),
              const SizedBox(width: 8),
              Text(
                isOut
                    ? 'Daily Cap Reached (${state.viewsToday}/${state.dailyLimit})'
                    : 'Free Tier: $remaining of ${state.dailyLimit} daily matches left',
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isOut ? AppColors.roseGlow : AppColors.textPure,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'UPGRADE ✨',
                  style: AppTypography.bodySmall.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyLimitReachedCard(
    BuildContext context,
    DiscoveryState state,
    DiscoveryNotifier notifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.champagneGold.withOpacity(0.15),
                  border: Border.all(color: AppColors.champagneGold, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.champagneGold.withOpacity(0.3),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded, size: 40, color: AppColors.champagneGold),
              ),
              const SizedBox(height: 20),
              Text(
                'Daily Match Limit Reached',
                style: AppTypography.headingLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                "You've completed your ${state.dailyLimit} free curated matches for today. Intentional marriages require proactive discovery—upgrade to explore 15 to 25+ verified partners daily.",
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.darkSlate,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderGold),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.alarm, size: 16, color: AppColors.champagneGold),
                    const SizedBox(width: 8),
                    Text(
                      'Resets at midnight or unlocks instantly',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              GoldButton(
                text: 'Upgrade for More Matches',
                onPressed: () => context.push('/paywall'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  side: const BorderSide(color: AppColors.borderSubtle),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                ),
                onPressed: () => context.go('/insights'),
                child: Text('View Marriage Insights', style: AppTypography.button.copyWith(color: AppColors.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpgradeFlierModal(
    BuildContext context,
    DiscoveryState state,
    DiscoveryNotifier notifier,
  ) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.88),
        padding: const EdgeInsets.all(20),
        child: Center(
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSubtle),
                    onPressed: () => notifier.dismissUpgradeFlier(),
                  ),
                ),
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [AppColors.champagneGold, AppColors.deepGold],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.champagneGold.withOpacity(0.4),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.lock_open_rounded, size: 34, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.champagneGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGold),
                  ),
                  child: Text(
                    'MEMBERSHIP CAP NOTICE',
                    style: AppTypography.bodySmall.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      color: AppColors.champagneGold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Daily Matching Limit Reached',
                  style: AppTypography.displayMedium.copyWith(fontSize: 20),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "You have reached your ${state.dailyLimit} daily candidate limit for the Free tier. Upgrade your registry tier now to unlock more verified matches immediately.",
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted, fontSize: 13, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.darkSlate,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: [
                      _buildPerkRow('15 to 100 AI-Curated verified matches daily'),
                      const SizedBox(height: 8),
                      _buildPerkRow('Unlimited intentional conversations'),
                      const SizedBox(height: 8),
                      _buildPerkRow('See who favorited your marriage vows'),
                      const SizedBox(height: 8),
                      _buildPerkRow('Priority placement in the Sovereign Registry'),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GoldButton(
                  text: 'Upgrade Now ✨',
                  onPressed: () {
                    notifier.dismissUpgradeFlier();
                    context.push('/paywall');
                  },
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => notifier.dismissUpgradeFlier(),
                  child: Text('Maybe Later', style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPerkRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.emeraldVerified, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textPure, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
