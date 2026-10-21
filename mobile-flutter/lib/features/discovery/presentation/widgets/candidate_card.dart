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
  int _currentPhotoIndex = 0;

  MatchProfile get candidate => widget.candidate;

  @override
  Widget build(BuildContext context) {
    final photos = candidate.photos;
    final hasMultiplePhotos = photos.length > 1;
    final photo = photos.isNotEmpty
        ? photos[_currentPhotoIndex.clamp(0, photos.length - 1)]
        : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?q=80&w=800';

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

            // 3. Extra Photos Navigation: Left/Right Tap Zones on the photo
            if (hasMultiplePhotos) ...[
              Positioned(
                top: 70,
                bottom: 120,
                left: 0,
                width: MediaQuery.of(context).size.width * 0.35,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_currentPhotoIndex > 0) {
                      setState(() => _currentPhotoIndex--);
                    }
                  },
                ),
              ),
              Positioned(
                top: 70,
                bottom: 120,
                right: 0,
                width: MediaQuery.of(context).size.width * 0.35,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () {
                    if (_currentPhotoIndex < photos.length - 1) {
                      setState(() => _currentPhotoIndex++);
                    }
                  },
                ),
              ),

              // Visible Chevron Buttons for Instant Photo Switching
              if (_currentPhotoIndex > 0)
                Positioned(
                  left: 10,
                  top: 0,
                  bottom: 120,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentPhotoIndex--);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.champagneGold.withValues(alpha: 0.6), width: 1),
                        ),
                        child: const Icon(Icons.chevron_left, color: AppColors.champagneGold, size: 20),
                      ),
                    ),
                  ),
                ),
              if (_currentPhotoIndex < photos.length - 1)
                Positioned(
                  right: 10,
                  top: 0,
                  bottom: 120,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _currentPhotoIndex++);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack.withValues(alpha: 0.65),
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.champagneGold.withValues(alpha: 0.6), width: 1),
                        ),
                        child: const Icon(Icons.chevron_right, color: AppColors.champagneGold, size: 20),
                      ),
                    ),
                  ),
                ),
            ],

            // 4. Story Progress Bars for Extra Pictures (if candidate has multiple photos)
            if (hasMultiplePhotos)
              Positioned(
                top: 10,
                left: 18,
                right: 18,
                child: Row(
                  children: List.generate(photos.length, (idx) {
                    final isActive = idx == _currentPhotoIndex;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _currentPhotoIndex = idx),
                        child: Container(
                          height: 3.5,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: isActive
                                ? AppColors.champagneGold
                                : Colors.white.withValues(alpha: 0.35),
                            boxShadow: isActive
                                ? [
                                    BoxShadow(
                                      color: AppColors.champagneGold.withValues(alpha: 0.6),
                                      blurRadius: 4,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

            // 5. Top Bar: Photo count badge & Golden Trust Badge
            Positioned(
              top: hasMultiplePhotos ? 20 : 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (hasMultiplePhotos)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _currentPhotoIndex = (_currentPhotoIndex + 1) % photos.length;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                        decoration: BoxDecoration(
                          color: AppColors.obsidianBlack.withValues(alpha: 0.82),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.borderGold, width: 0.9),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.photo_library_outlined, size: 12, color: AppColors.champagneGold),
                            const SizedBox(width: 4),
                            Text(
                              '${_currentPhotoIndex + 1}/${photos.length} PHOTOS',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.champagneGold,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Golden Trust Badge in percentage
                  Container(
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
                  if (candidate.isClosestAvailable) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.obsidianBlack.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFD4AF37), width: 1.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: Color(0xFFD4AF37), size: 12),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              'CLOSEST AVAILABLE MATCH FOR NOW',
                              style: const TextStyle(
                                color: Color(0xFFD4AF37),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
