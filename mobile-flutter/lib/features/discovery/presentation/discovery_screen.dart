import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../models/match_profile.dart';
import '../providers/discovery_provider.dart';
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
                    ? _buildEmptyRegistry(notifier)
                    : Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: CardSwiper(
                                controller: _swiperController,
                                cardsCount: state.candidates.length,
                                cardBuilder: (context, index, percentX, percentY) {
                                  final candidate = state.candidates[index];
                                  return CandidateCard(
                                    candidate: candidate,
                                    onDetailsTap: () {
                                      context.push('/profile-detail', extra: candidate);
                                    },
                                  );
                                },
                                onSwipe: (previousIndex, currentIndex, direction) {
                                  final candidate = state.candidates[previousIndex];
                                  if (direction == CardSwiperDirection.right) {
                                    notifier.likeCandidate(candidate);
                                  } else {
                                    notifier.passCandidate(candidate);
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
                                // Pass Button
                                _buildActionButton(
                                  icon: Icons.close,
                                  color: AppColors.textSubtle,
                                  onTap: () => _swiperController.swipe(CardSwiperDirection.left),
                                ),
                                const SizedBox(width: 24),

                                // Vow / Superlike Button
                                _buildActionButton(
                                  icon: Icons.star,
                                  color: AppColors.champagneGold,
                                  size: 64,
                                  onTap: () {
                                    if (state.candidates.isNotEmpty) {
                                      notifier.likeCandidate(state.candidates.first);
                                    }
                                  },
                                ),
                                const SizedBox(width: 24),

                                // Like Button
                                _buildActionButton(
                                  icon: Icons.favorite,
                                  color: AppColors.roseGlow,
                                  onTap: () => _swiperController.swipe(CardSwiperDirection.right),
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

  Widget _buildEmptyRegistry(DiscoveryNotifier notifier) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.workspace_premium, size: 64, color: AppColors.champagneGold.withOpacity(0.8)),
              const SizedBox(height: 20),
              Text('Registry Refreshed', style: AppTypography.headingLarge),
              const SizedBox(height: 10),
              Text(
                'You have reviewed all available verified candidates matching your marital criteria.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              GoldButton(
                text: 'Load Next Candidates',
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
                const Icon(Icons.favorite, size: 56, color: AppColors.roseGlow),
                const SizedBox(height: 16),
                Text('MUTUAL ALIGNMENT', style: AppTypography.displayMedium.copyWith(fontSize: 22)),
                const SizedBox(height: 8),
                Text(
                  'You and ${candidate.name} share ${candidate.compatibilityScore}% verified compatibility.',
                  style: AppTypography.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                GoldButton(
                  text: 'Open Conversation',
                  onPressed: () {
                    final id = candidate.id;
                    notifier.dismissMatchModal();
                    context.push('/chat/$id');
                  },
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
