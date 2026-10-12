import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/verified_badge.dart';
import '../models/match_profile.dart';

class ProfileDetailScreen extends StatelessWidget {
  final MatchProfile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: CustomScrollView(
        slivers: [
          // Collapsible Image AppBar
          SliverAppBar(
            expandedHeight: 420,
            pinned: true,
            backgroundColor: AppColors.obsidianBlack,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.champagneGold, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: profile.photos.first,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.obsidianBlack.withOpacity(0.85),
                          AppColors.obsidianBlack,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 0.85, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Profile Body Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, Age & Verified
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${profile.name}, ${profile.age}',
                                style: AppTypography.displayMedium.copyWith(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              const VerifiedBadge(size: 20),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${profile.city}, ${profile.country}',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.champagneGold.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.champagneGold, width: 1),
                        ),
                        child: Text(
                          '${profile.compatibilityScore}%',
                          style: AppTypography.headingLarge.copyWith(
                            color: AppColors.champagneGold,
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // AI Compatibility Analysis Card
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome, color: AppColors.champagneGold, size: 18),
                            const SizedBox(width: 8),
                            Text('WHY YOU MATCHED', style: AppTypography.headingMedium.copyWith(fontSize: 15)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          profile.aiExplanation,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPure,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildAlignmentBar('Emotional Alignment', profile.emotionalAlignment),
                        const SizedBox(height: 12),
                        _buildAlignmentBar('Values Alignment', profile.valuesAlignment),
                        const SizedBox(height: 12),
                        _buildAlignmentBar('Lifestyle Compatibility', profile.lifestyleCompatibility),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personal Bio
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CANDIDATE BIOGRAPHY', style: AppTypography.headingMedium.copyWith(fontSize: 14)),
                        const SizedBox(height: 10),
                        Text(profile.bio, style: AppTypography.bodyMedium),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sacred Values
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CORE VALUES', style: AppTypography.headingMedium.copyWith(fontSize: 14)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.personalValues.map((val) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.darkCardElevated,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.borderGold, width: 0.8),
                              ),
                              child: Text(
                                val,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.champagneGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Connect Action Button
                  GoldButton(
                    text: 'Initiate Marriage Conversation',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () {
                      context.pop();
                      context.go('/chat/${profile.id}');
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlignmentBar(String label, int score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall),
            Text('$score%', style: AppTypography.bodySmall.copyWith(color: AppColors.champagneGold, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score / 100,
            backgroundColor: AppColors.darkSlate,
            valueColor: const AlwaysStoppedAnimation(AppColors.champagneGold),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
