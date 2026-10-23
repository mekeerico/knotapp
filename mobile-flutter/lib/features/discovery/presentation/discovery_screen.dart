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
import '../../auth/models/user_model.dart';
import 'widgets/candidate_card.dart';

class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  final CardSwiperController _swiperController = CardSwiperController();
  int _currentCardIndex = 0;
  int _sessionSwipes = 0;
  bool _hasShownExhaustedOrCycleNotice = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(discoveryProvider.notifier).loadCandidates();
    });
  }

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

    // Automatically reload candidate deck whenever auth state resolves or user gender changes
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user?.id != next.user?.id ||
          previous?.user?.gender != next.user?.gender ||
          previous?.user?.preferredGender != next.user?.preferredGender) {
        notifier.loadCandidates();
      }
    });

    // Strictly enforce opposite-gender filtering on candidates rendered in the UI
    final displayCandidates = DiscoveryNotifier.filterOppositeGender(
      candidates: state.candidates,
      currentUser: authState.user,
    );

    ref.listen<DiscoveryState>(discoveryProvider, (previous, next) {
      if (next.limitNoticeMessage != null && next.limitNoticeMessage != previous?.limitNoticeMessage) {
        final message = next.limitNoticeMessage!;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.darkSlate,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: AppColors.champagneGold, width: 1.2),
            ),
            duration: const Duration(seconds: 8),
            content: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.champagneGold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPure,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    context.push('/paywall');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'UPGRADE ✨',
                      style: AppTypography.bodySmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSubtle, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                  tooltip: 'Dismiss',
                ),
              ],
            ),
          ),
        );
        notifier.clearLimitNotice();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: const KnotAppBar(
        showLogo: true,
        showNotificationBell: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Ambient background radial purple/gold glow
            Positioned(
              top: -100,
              left: -60,
              right: -60,
              child: IgnorePointer(
                child: Container(
                  height: 360,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        AppColors.royalPurple.withValues(alpha: 0.35),
                        AppColors.champagneGold.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                      radius: 0.85,
                    ),
                  ),
                ),
              ),
            ),
            state.isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(AppColors.champagneGold),
                    ),
                  )
                : displayCandidates.isEmpty
                    ? _buildEmptyRegistry(notifier, authState.user)
                    : Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: CardSwiper(
                                key: ValueKey('deck_${displayCandidates.length}'),
                                controller: _swiperController,
                                cardsCount: displayCandidates.length,
                                numberOfCardsDisplayed: 1,
                                backCardOffset: Offset.zero,
                                isLoop: true,
                                onEnd: () {
                                  // In continuous loop mode, candidates remain available
                                },
                                cardBuilder: (context, index, percentX, percentY) {
                                  if (index < 0 || index >= displayCandidates.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final candidate = displayCandidates[index];
                                  return CandidateCard(
                                    candidate: candidate,
                                    onDetailsTap: () {
                                      context.push('/profile-detail', extra: candidate);
                                    },
                                  );
                                },
                                onSwipe: (previousIndex, currentIndex, direction) {
                                  if (currentIndex != null && displayCandidates.isNotEmpty) {
                                    setState(() {
                                      _currentCardIndex = currentIndex % displayCandidates.length;
                                      _sessionSwipes++;
                                    });

                                    // After scrolling through available matches over again for the 2nd time:
                                    if (_sessionSwipes >= displayCandidates.length * 2 && !_hasShownExhaustedOrCycleNotice) {
                                      _hasShownExhaustedOrCycleNotice = true;
                                      final isExhausted = state.hasExceededLimit || state.viewsToday >= state.dailyLimit;
                                      WidgetsBinding.instance.addPostFrameCallback((_) {
                                        if (mounted) {
                                          _showLoopLimitNotice(context, authState.user, isExhausted);
                                        }
                                      });
                                    }
                                  }
                                  if (previousIndex >= 0 && previousIndex < displayCandidates.length) {
                                    final candidate = displayCandidates[previousIndex];
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

                          // Action Buttons Bar: Pass & Connect
                          Padding(
                            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: 8),
                            child: Row(
                              children: [
                                // Pass Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (displayCandidates.isNotEmpty) {
                                        _swiperController.swipe(CardSwiperDirection.left);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF191E2E),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(color: const Color(0xFF374151), width: 1),
                                      ),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Pass',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 14),

                                // Connect Button
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      if (displayCandidates.isNotEmpty) {
                                        final idx = _currentCardIndex.clamp(0, displayCandidates.length - 1);
                                        context.push('/profile-detail', extra: displayCandidates[idx]);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFE27D8D), Color(0xFF8C52FF)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(999),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFE27D8D).withOpacity(0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      alignment: Alignment.center,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: const [
                                          Text(
                                            'Connect',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Icon(Icons.favorite_border, color: Colors.white, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
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

  Widget _buildEmptyRegistry(DiscoveryNotifier notifier, UserModel? currentUser) {
    bool isMaleUser = DiscoveryNotifier.isMale(currentUser?.gender);
    bool isFemaleUser = DiscoveryNotifier.isFemale(currentUser?.gender);

    if (!isMaleUser && !isFemaleUser) {
      if (DiscoveryNotifier.isFemale(currentUser?.preferredGender)) isMaleUser = true;
      if (DiscoveryNotifier.isMale(currentUser?.preferredGender)) isFemaleUser = true;
    }
    if (!isMaleUser && !isFemaleUser) {
      final name = currentUser?.firstName ?? currentUser?.fullName ?? '';
      if (DiscoveryNotifier.isMaleName(name)) isMaleUser = true;
      if (DiscoveryNotifier.isFemaleName(name)) isFemaleUser = true;
    }
    if (!isMaleUser && !isFemaleUser) {
      final emailPrefix = (currentUser?.email ?? '').split('@').first.toLowerCase();
      if (DiscoveryNotifier.isMaleName(emailPrefix)) isMaleUser = true;
      if (DiscoveryNotifier.isFemaleName(emailPrefix)) isFemaleUser = true;
    }
    if (!isMaleUser && !isFemaleUser) {
      isMaleUser = true; // Default
    }

    final targetCohort = isMaleUser ? 'eligible ladies' : 'eligible gentlemen';

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

