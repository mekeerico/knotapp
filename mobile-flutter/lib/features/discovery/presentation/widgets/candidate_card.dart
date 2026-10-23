import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/knot_image.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../models/match_profile.dart';

class CandidateCard extends StatefulWidget {
  final MatchProfile candidate;
  final VoidCallback onDetailsTap;

  const CandidateCard({
    super.key,
    required this.candidate,
    required this.onDetailsTap,
  });

  @override
  State<CandidateCard> createState() => _CandidateCardState();
}

class _CandidateCardState extends State<CandidateCard> {
  MatchProfile get candidate => widget.candidate;

  @override
  Widget build(BuildContext context) {
    final photos = candidate.photos;
    final photo = photos.isNotEmpty ? photos.first : '';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.obsidianBlack,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderGold, width: 1.0),
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
            // 1. High-Resolution Background Photo
            Positioned.fill(
              child: KnotImage(
                imageUrl: photo,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(24),
              ),
            ),

            // 2. Low-profile Vignette Scrim (concentrated ONLY at the bottom 38% to keep face/chest 100% clear)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.0),
                        Colors.black.withValues(alpha: 0.45),
                        Colors.black.withValues(alpha: 0.92),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.60, 0.80, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Top Bar: Golden Trust Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFD4AF37).withOpacity(0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 13,
                          color: Color(0xFF0B0E14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'TRUST ${candidate.trustScore > 0 ? candidate.trustScore : 97}%',
                          style: const TextStyle(
                            color: Color(0xFF0B0E14),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 6. Bottom Profile Info: Name, Age, Verified Checkmark & Profession, City, Country
            Positioned(
              bottom: 18,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row 1: Candidate First Name & Age + Golden Verified Badge
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${candidate.name.trim().split(RegExp(r'\s+')).first}, ${candidate.age}',
                          style: AppTypography.headingLarge.copyWith(
                            fontSize: 22,
                            color: AppColors.textPure,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const VerifiedBadge(size: 18),
                    ],
                  ),
                  const SizedBox(height: 5),

                  // Row 2: Profession / Occupation • City, Country
                  Row(
                    children: [
                      const Icon(Icons.work_outline, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          candidate.occupation,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text('•', style: TextStyle(color: AppColors.textSubtle, fontSize: 11)),
                      const SizedBox(width: 6),
                      const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          '${candidate.city}, ${candidate.country}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
