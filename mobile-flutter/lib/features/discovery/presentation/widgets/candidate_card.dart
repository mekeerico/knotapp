import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../models/match_profile.dart';

class CandidateCard extends StatelessWidget {
  final MatchProfile candidate;
  final VoidCallback onDetailsTap;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onDetailsTap,
  });

  @override
  Widget build(BuildContext context) {
    final photo = candidate.photos.isNotEmpty
        ? candidate.photos.first
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.55),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // High-Resolution Background Photo
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: photo,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.darkSlate,
                  child: const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.champagneGold),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.darkSlate,
                  child: const Icon(Icons.person, size: 80, color: AppColors.textSubtle),
                ),
              ),
            ),

            // Deep Vignette Gradient Scrim
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.92),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.45, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // Top Compatibility Pill & Verified Status
            Positioned(
              top: 18,
              left: 18,
              right: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.obsidianBlack.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.champagneGold, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.champagneGold.withOpacity(0.25),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          size: 14,
                          color: AppColors.roseGlow,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${candidate.compatibilityScore}% ALIGNED',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.champagneGold,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (candidate.isVerified)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianBlack.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGold, width: 0.8),
                      ),
                      child: const VerifiedBadge(size: 16, showLabel: true, label: 'GOLD'),
                    ),
                ],
              ),
            ),

            // Bottom Profile Information
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name, Age & Verified Checkmark
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${candidate.name}, ${candidate.age}',
                          style: AppTypography.headingLarge.copyWith(
                            fontSize: 24,
                            color: AppColors.textPure,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const VerifiedBadge(size: 20),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Occupation & Location
                  Row(
                    children: [
                      const Icon(Icons.work_outline, size: 15, color: AppColors.champagneGold),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          candidate.occupation,
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 15, color: AppColors.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '${candidate.city}, ${candidate.country}',
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Trait Chips
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _buildMiniChip(candidate.personalityArchetype, Icons.psychology_outlined),
                      _buildMiniChip(candidate.marriageTimeline, Icons.access_time),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tap for Deep Analysis Trigger
                  GestureDetector(
                    onTap: onDetailsTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'View Psychological Compatibility & Vows',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.champagneGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            size: 13,
                            color: AppColors.champagneGold,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.darkSlate.withOpacity(0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderGold.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.champagneGold),
          const SizedBox(width: 4),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 11,
              color: AppColors.textPure,
            ),
          ),
        ],
      ),
    );
  }
}
