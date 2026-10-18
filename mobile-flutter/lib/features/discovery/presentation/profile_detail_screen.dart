import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_image.dart';
import '../../../core/widgets/verified_badge.dart';
import '../models/match_profile.dart';

class ProfileDetailScreen extends StatefulWidget {
  final MatchProfile profile;

  const ProfileDetailScreen({super.key, required this.profile});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  int _selectedPhotoIndex = 0;

  MatchProfile get profile => widget.profile;

  String _formatLocation(String city, String state, String country) {
    final parts = [city, state, country]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Not specified';
  }

  @override
  Widget build(BuildContext context) {
    final photos = profile.photos;
    final activePhoto = photos.isNotEmpty
        ? photos[_selectedPhotoIndex.clamp(0, photos.length - 1)]
        : '';

    final residenceFormatted = _formatLocation(
      profile.city,
      profile.residenceState,
      profile.country,
    );

    final originFormatted = _formatLocation(
      profile.originCity,
      profile.originState,
      profile.originCountry.isNotEmpty ? profile.originCountry : profile.country,
    );

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
                  color: AppColors.obsidianBlack.withValues(alpha: 0.65),
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
                  KnotImage(
                    imageUrl: activePhoto,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.obsidianBlack.withValues(alpha: 0.85),
                          AppColors.obsidianBlack,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.55, 0.85, 1.0],
                      ),
                    ),
                  ),
                  if (photos.length > 1)
                    Positioned(
                      bottom: 16,
                      left: 20,
                      right: 20,
                      child: SizedBox(
                        height: 54,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: photos.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final isSelected = idx == _selectedPhotoIndex;
                            return GestureDetector(
                              onTap: () => setState(() => _selectedPhotoIndex = idx),
                              child: Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.champagneGold
                                        : Colors.white.withValues(alpha: 0.35),
                                    width: isSelected ? 2.2 : 1.0,
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: KnotImage(
                                    imageUrl: photos[idx],
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            );
                          },
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
                  // Name, Age, Verified & Match Score Badge (Responsive Row — Never Clips)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    '${profile.name}, ${profile.age}',
                                    style: AppTypography.displayMedium.copyWith(fontSize: 22),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const VerifiedBadge(size: 20),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 15,
                                  color: AppColors.champagneGold,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    residenceFormatted,
                                    style: AppTypography.bodyMedium,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.champagneGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.champagneGold, width: 1.2),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${profile.compatibilityScore}%',
                              style: AppTypography.headingLarge.copyWith(
                                color: AppColors.champagneGold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              'MATCH',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.champagneGold,
                                fontSize: 9,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // 1. AI Compatibility Analysis Card
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
                        _buildAlignmentBar('Communication Alignment', profile.communicationStyle),
                        const SizedBox(height: 12),
                        _buildAlignmentBar('Values Alignment', profile.valuesAlignment),
                        const SizedBox(height: 12),
                        _buildAlignmentBar('Lifestyle Compatibility', profile.lifestyleCompatibility),
                        const SizedBox(height: 16),
                        const Divider(color: AppColors.borderSubtle, height: 1),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: _buildCompactStat(
                                'Archetype',
                                profile.personalityArchetype,
                                Icons.psychology_outlined,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildCompactStat(
                                'Attachment Style',
                                profile.attachmentStyle,
                                Icons.favorite_border,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 2. Personal Bio
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.person_outline, 'CANDIDATE BIOGRAPHY'),
                        const SizedBox(height: 10),
                        Text(
                          profile.bio,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textPure,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 3. Heritage & Origin (Current Residence is already shown in the top header)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.public, 'HERITAGE & ORIGIN'),
                        const SizedBox(height: 14),
                        _buildDetailRow(
                          icon: Icons.account_balance_outlined,
                          label: 'Ancestral Origin',
                          value: originFormatted,
                        ),
                        if (profile.culturalBackground.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.diversity_3_outlined,
                            label: 'Cultural Background',
                            value: profile.culturalBackground,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 4. Partner Preferences (Residence & Heritage/Origin of Desired Partner)
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.person_search_outlined, 'PARTNER PREFERENCES'),
                        const SizedBox(height: 14),
                        _buildDetailRow(
                          icon: Icons.flag_outlined,
                          label: 'Preferred Partner Country of Residence',
                          value: profile.preferredResidenceCountry.isNotEmpty
                              ? profile.preferredResidenceCountry
                              : 'Any Country',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.map_outlined,
                          label: 'Preferred Partner State / Province / Region',
                          value: profile.preferredResidenceState.isNotEmpty
                              ? profile.preferredResidenceState
                              : 'Any State/Province/Region',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.public_outlined,
                          label: 'Preferred Partner Heritage Country',
                          value: profile.preferredOriginCountry.isNotEmpty
                              ? profile.preferredOriginCountry
                              : 'Any Country',
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.diversity_2_outlined,
                          label: 'Native Heritage / Ethno-Cultural Background',
                          value: profile.preferredOriginState.isNotEmpty
                              ? profile.preferredOriginState
                              : 'Any Heritage',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Vocation, Education & Faith
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.work_outline, 'VOCATION, EDUCATION & FAITH'),
                        const SizedBox(height: 14),
                        _buildDetailRow(
                          icon: Icons.business_center_outlined,
                          label: 'Profession / Occupation',
                          value: profile.occupation,
                        ),
                        if (profile.education.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.school_outlined,
                            label: 'Highest Educational Qualification',
                            value: profile.education,
                          ),
                        ],
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.church_outlined,
                          label: 'Faith / Religion',
                          value: profile.religion,
                        ),
                        if (profile.careerGoals.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.trending_up,
                            label: 'Career & Life Ambitions',
                            value: profile.careerGoals,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 5. Languages Spoken
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.translate, 'LANGUAGES SPOKEN'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.languagesSpoken.map((lang) => _buildGoldPill(lang)).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 6. Past Marriage History & Lifestyle
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.history_edu_outlined, 'MARITAL HISTORY & LIFESTYLE'),
                        const SizedBox(height: 14),
                        _buildDetailRow(
                          icon: Icons.favorite_outline,
                          label: 'Past Marital History',
                          value: profile.maritalStatus,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.child_care_outlined,
                          label: 'Current Children Status',
                          value: profile.childrenStatus,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.smoke_free_outlined,
                          label: 'Smoking Habits',
                          value: profile.smoking,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.local_bar_outlined,
                          label: 'Drinking Habits',
                          value: profile.drinking,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 7. Future Marriage Plans & Aspirations
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.diamond_outlined, 'FUTURE MARRIAGE PLANS & ASPIRATIONS'),
                        const SizedBox(height: 14),
                        _buildDetailRow(
                          icon: Icons.schedule_outlined,
                          label: 'Marriage / Vow Timeline',
                          value: profile.marriageTimeline,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.family_restroom_outlined,
                          label: 'Future Children & Family Plans',
                          value: profile.childrenPreference,
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          icon: Icons.flight_takeoff_outlined,
                          label: 'Willingness to Relocate',
                          value: profile.willingToRelocate,
                        ),
                        if (profile.marriageExpectations.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.volunteer_activism_outlined,
                            label: 'Marriage Vision & Expectations',
                            value: profile.marriageExpectations,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),

                  // 8. Core Values & Ideal Partner Qualities
                  GlassCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader(Icons.verified_outlined, 'CORE VALUES & COVENANT TRAITS'),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profile.personalValues.map((val) => _buildGoldPill(val)).toList(),
                        ),
                        if (profile.idealPartnerTraits.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'DESIRED PARTNER QUALITIES',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textSubtle,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.idealPartnerTraits.map((t) => _buildGoldPill(t)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Connect Action Button
                  GoldButton(
                    text: 'Initiate Marriage Conversation',
                    icon: Icons.chat_bubble_outline,
                    onPressed: () {
                      context.push('/chat/${profile.id}', extra: profile);
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

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.champagneGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingMedium.copyWith(fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.darkCardElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Icon(icon, size: 16, color: AppColors.champagneGold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPure,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.champagneGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10.5)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPure,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoldPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGold, width: 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.champagneGold,
          fontWeight: FontWeight.bold,
        ),
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
            Text(
              '$score%',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.champagneGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (score.clamp(0, 100)) / 100,
            backgroundColor: AppColors.darkSlate,
            valueColor: const AlwaysStoppedAnimation(AppColors.champagneGold),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
