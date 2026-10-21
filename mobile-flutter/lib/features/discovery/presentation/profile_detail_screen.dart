import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/auto_hiding_floating_bar.dart';
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
  static const Color _pearlGrey = Color(0xFFD1D5DC);   // Soft Off-White / Pearl Grey
  static const Color _mutedSlate = Color(0xFF94A3B8);  // Muted Slate Grey / Cool Slate Blue
  static const Color _trustGold = Color(0xFFD4AF37);   // Golden color like Trust icon
  static const Color _deepGreen = Color(0xFF10B981);   // Deep green
  static const Color _deepPink = Color(0xFFE11D48);    // Deep pink

  int _selectedPhotoIndex = 0;
  late final PageController _photoPageController;

  MatchProfile get profile => widget.profile;

  @override
  void initState() {
    super.initState();
    _photoPageController = PageController();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  String _formatLocation(String city, String state, String country) {
    final parts = [city, state, country]
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return parts.isNotEmpty ? parts.join(', ') : 'Not specified';
  }

  void _openFullscreenGallery(BuildContext context, List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.96),
      builder: (context) {
        int currentIndex = initialIndex;
        final pageCtrl = PageController(initialPage: initialIndex);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Scaffold(
              backgroundColor: Colors.transparent,
              body: SafeArea(
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: pageCtrl,
                      itemCount: photos.length,
                      onPageChanged: (idx) {
                        setDialogState(() => currentIndex = idx);
                        setState(() {
                          _selectedPhotoIndex = idx;
                          if (_photoPageController.hasClients) {
                            _photoPageController.jumpToPage(idx);
                          }
                        });
                      },
                      itemBuilder: (context, idx) {
                        return InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 3.5,
                          child: Center(
                            child: KnotImage(
                              imageUrl: photos[idx],
                              fit: BoxFit.contain,
                            ),
                          ),
                        );
                      },
                    ),

                    // Top Bar with Close button & Photo Count
                    Positioned(
                      top: 12,
                      left: 16,
                      right: 16,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.obsidianBlack.withOpacity(0.75),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderGold, width: 0.8),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close, color: AppColors.champagneGold, size: 20),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.obsidianBlack.withOpacity(0.75),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.borderGold, width: 0.8),
                            ),
                            child: Text(
                              '${currentIndex + 1} / ${photos.length}',
                              style: AppTypography.titleMedium.copyWith(
                                color: AppColors.champagneGold,
                                fontSize: 13,
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
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = profile.photos;

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
      body: AutoHidingFloatingBar(
        bottomOffset: 0,
        topOffset: 0,
        topFloatingContent: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.obsidianBlack.withOpacity(0.88),
                AppColors.obsidianBlack.withOpacity(0.45),
                Colors.transparent,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 4,
            left: 8,
            right: 16,
            bottom: 12,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.obsidianBlack.withOpacity(0.75),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderGold.withOpacity(0.4), width: 1),
                ),
                child: const Icon(Icons.arrow_back, color: AppColors.champagneGold, size: 20),
              ),
              onPressed: () => context.pop(),
            ),
          ),
        ),
        floatingContent: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.obsidianBlack.withOpacity(0.75),
                AppColors.obsidianBlack.withOpacity(0.96),
                AppColors.obsidianBlack,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.25, 0.65, 1.0],
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 14,
            bottom: MediaQuery.of(context).padding.bottom + 12,
          ),
          child: GoldButton(
            text: 'Initiate Marriage Conversation',
            icon: Icons.chat_bubble_outline,
            onPressed: () {
              context.push('/chat/${profile.id}', extra: profile);
            },
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // Collapsible Image AppBar with Swipable PageView, Story Bars & Fullscreen Preview
            SliverAppBar(
              expandedHeight: 440,
              pinned: false,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.obsidianBlack,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Swipable Carousel for all pictures
                    PageView.builder(
                      controller: _photoPageController,
                      itemCount: photos.isNotEmpty ? photos.length : 1,
                      onPageChanged: (idx) => setState(() => _selectedPhotoIndex = idx),
                      itemBuilder: (context, idx) {
                        final photoUrl = photos.isNotEmpty ? photos[idx] : '';
                        return GestureDetector(
                          onTap: () => _openFullscreenGallery(context, photos, _selectedPhotoIndex),
                          child: KnotImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),

                    // Left/Right Tap zones for quick photo flip
                    if (photos.length > 1) ...[
                      Positioned(
                        top: 80,
                        bottom: 90,
                        left: 0,
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_selectedPhotoIndex > 0) {
                              _photoPageController.previousPage(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                      Positioned(
                        top: 80,
                        bottom: 90,
                        right: 0,
                        width: MediaQuery.of(context).size.width * 0.35,
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () {
                            if (_selectedPhotoIndex < photos.length - 1) {
                              _photoPageController.nextPage(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                      ),
                    ],

                    // Vignette Scrim (Keeping face completely clear)
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.35),
                            Colors.transparent,
                            AppColors.obsidianBlack.withOpacity(0.75),
                            AppColors.obsidianBlack,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.35, 0.82, 1.0],
                        ),
                      ),
                    ),

                    // Top Segmented Story Indicators (1, 2, or 3 bars)
                    if (photos.length > 1)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 10,
                        left: 64,
                        right: 64,
                        child: Row(
                          children: List.generate(photos.length, (idx) {
                            final isActive = idx == _selectedPhotoIndex;
                            return Expanded(
                              child: Container(
                                height: 3.5,
                                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  color: isActive
                                      ? AppColors.champagneGold
                                      : Colors.white.withOpacity(0.35),
                                  boxShadow: isActive
                                      ? [
                                          BoxShadow(
                                            color: AppColors.champagneGold.withOpacity(0.7),
                                            blurRadius: 4,
                                          )
                                        ]
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),

                    // Photo Count & Tap to Enlarge Pill
                    if (photos.length > 1)
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 20,
                        right: 16,
                        child: GestureDetector(
                          onTap: () => _openFullscreenGallery(context, photos, _selectedPhotoIndex),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.obsidianBlack.withOpacity(0.78),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.champagneGold.withOpacity(0.8), width: 0.9),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.photo_library_outlined, size: 13, color: AppColors.champagneGold),
                                const SizedBox(width: 5),
                                Text(
                                  '${_selectedPhotoIndex + 1}/${photos.length}',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: AppColors.champagneGold,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Thumbnail Selector Strip at Bottom of Header
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
                                onTap: () {
                                  setState(() => _selectedPhotoIndex = idx);
                                  _photoPageController.animateToPage(
                                    idx,
                                    duration: const Duration(milliseconds: 240),
                                    curve: Curves.easeInOut,
                                  );
                                },
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.champagneGold
                                          : Colors.white.withOpacity(0.35),
                                      width: isSelected ? 2.5 : 1.0,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.champagneGold.withOpacity(0.4),
                                              blurRadius: 8,
                                            )
                                          ]
                                        : null,
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
                    // Name, Age, Verified & Match Score Badge
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: _trustGold,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: _trustGold.withOpacity(0.35),
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
                                '${profile.compatibilityScore}% MATCH',
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
                    const SizedBox(height: 22),

                    // 1. Compatibility Profile Card
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'COMPATIBILITY PROFILE',
                                style: AppTypography.headingMedium.copyWith(
                                  fontSize: 14,
                                  color: _trustGold,
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _buildAlignmentBar(
                            'Values Alignment',
                            profile.valuesAlignment > 0 ? profile.valuesAlignment : 95,
                            barColor: const Color(0xFFD4AF37), // Golden
                            textColor: const Color(0xFFD4AF37),
                          ),
                          const SizedBox(height: 14),
                          _buildAlignmentBar(
                            'Emotional Synergy',
                            profile.emotionalAlignment > 0 ? profile.emotionalAlignment : 91,
                            barColor: const Color(0xFFE27D8D), // Pink / Velvet Rose
                            textColor: const Color(0xFFE27D8D),
                          ),
                          const SizedBox(height: 14),
                          _buildAlignmentBar(
                            'Communication Match',
                            profile.communicationStyle > 0 ? profile.communicationStyle : 88,
                            barColor: Colors.white, // Crisp White
                            textColor: Colors.white,
                          ),
                          const SizedBox(height: 18),
                          const Divider(color: AppColors.borderSubtle, height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _buildCompactStat(
                                  'Archetype',
                                  profile.personalityArchetype,
                                  Icons.psychology_outlined,
                                  iconColor: _trustGold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildCompactStat(
                                  'Attachment Style',
                                  profile.attachmentStyle,
                                  Icons.favorite_border,
                                  iconColor: _deepGreen,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2. Why You Matched Card (Separated Card)
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.auto_awesome, color: _trustGold, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                'Why You Matched',
                                style: AppTypography.headingMedium.copyWith(
                                  fontSize: 15,
                                  color: _trustGold,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _formatConciseAiExplanation(profile.aiExplanation, profile),
                            style: AppTypography.bodyMedium.copyWith(
                              color: _mutedSlate,
                              height: 1.5,
                            ),
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
                          _buildSectionHeader(Icons.person_outline, 'CANDIDATE BIOGRAPHY', iconColor: AppColors.champagneGold),
                          const SizedBox(height: 10),
                          Text(
                            profile.bio,
                            style: AppTypography.bodyMedium.copyWith(
                              color: _mutedSlate,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 3. Heritage & Origin
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.public, 'HERITAGE & ORIGIN', iconColor: _trustGold),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            icon: Icons.account_balance_outlined,
                            label: 'Ancestral Origin',
                            value: originFormatted,
                            iconColor: _trustGold,
                            valueColor: _pearlGrey,
                          ),
                          if (profile.culturalBackground.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.diversity_3_outlined,
                              label: 'Cultural Background',
                              value: profile.culturalBackground,
                              iconColor: _trustGold,
                              valueColor: _pearlGrey,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 4. Partner Preferences
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.person_search_outlined, 'PARTNER PREFERENCES', iconColor: _deepPink),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            icon: Icons.flag_outlined,
                            label: 'Preferred Partner Country of Residence',
                            value: profile.preferredResidenceCountry.isNotEmpty
                                ? profile.preferredResidenceCountry
                                : 'Any Country',
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.map_outlined,
                            label: 'Preferred Partner State / Province / Region',
                            value: profile.preferredResidenceState.isNotEmpty
                                ? profile.preferredResidenceState
                                : 'Any State/Province/Region',
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.public_outlined,
                            label: 'Preferred Partner Heritage Country',
                            value: profile.preferredOriginCountry.isNotEmpty
                                ? profile.preferredOriginCountry
                                : 'Any Country',
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.diversity_2_outlined,
                            label: 'Native Heritage / Ethno-Cultural Background',
                            value: profile.preferredOriginState.isNotEmpty
                                ? profile.preferredOriginState
                                : 'Any Heritage',
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
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
                          _buildSectionHeader(Icons.work_outline, 'VOCATION, EDUCATION & FAITH', iconColor: _deepGreen),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            icon: Icons.business_center_outlined,
                            label: 'Profession / Occupation',
                            value: profile.occupation,
                            iconColor: _deepGreen,
                            valueColor: _pearlGrey,
                          ),
                          if (profile.education.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.school_outlined,
                              label: 'Highest Educational Qualification',
                              value: profile.education,
                              iconColor: _deepGreen,
                              valueColor: _pearlGrey,
                            ),
                          ],
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.church_outlined,
                            label: 'Faith / Religion',
                            value: profile.religion,
                            iconColor: _deepGreen,
                            valueColor: _pearlGrey,
                          ),
                          if (profile.careerGoals.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.trending_up,
                              label: 'Career & Life Ambitions',
                              value: profile.careerGoals,
                              iconColor: _deepGreen,
                              valueColor: _pearlGrey,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 6. Languages Spoken
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.translate, 'LANGUAGES SPOKEN', iconColor: _trustGold),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.languagesSpoken.map((lang) => _buildGoldPill(lang, textColor: _mutedSlate)).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 7. Past Marriage History & Lifestyle
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.history_edu_outlined, 'MARITAL HISTORY & LIFESTYLE', iconColor: _deepPink),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            icon: Icons.favorite_outline,
                            label: 'Past Marital History',
                            value: profile.maritalStatus,
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.child_care_outlined,
                            label: 'Current Children Status',
                            value: profile.childrenStatus,
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.smoke_free_outlined,
                            label: 'Smoking Habits',
                            value: profile.smoking,
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.local_bar_outlined,
                            label: 'Drinking Habits',
                            value: profile.drinking,
                            iconColor: _deepPink,
                            valueColor: _pearlGrey,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 8. Future Marriage Plans & Aspirations
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.diamond_outlined, 'FUTURE MARRIAGE PLANS & ASPIRATIONS', iconColor: _trustGold),
                          const SizedBox(height: 14),
                          _buildDetailRow(
                            icon: Icons.schedule_outlined,
                            label: 'Marriage / Vow Timeline',
                            value: profile.marriageTimeline,
                            iconColor: _trustGold,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.family_restroom_outlined,
                            label: 'Future Children & Family Plans',
                            value: profile.childrenPreference,
                            iconColor: _trustGold,
                            valueColor: _pearlGrey,
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            icon: Icons.flight_takeoff_outlined,
                            label: 'Willingness to Relocate',
                            value: profile.willingToRelocate,
                            iconColor: _trustGold,
                            valueColor: _pearlGrey,
                          ),
                          if (profile.marriageExpectations.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow(
                              icon: Icons.volunteer_activism_outlined,
                              label: 'Marriage Vision & Expectations',
                              value: profile.marriageExpectations,
                              iconColor: _trustGold,
                              valueColor: _pearlGrey,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 9. Core Values & Ideal Partner Qualities
                    GlassCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(Icons.verified_outlined, 'CORE VALUES & COVENANT TRAITS', iconColor: _deepGreen),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: profile.personalValues.map((val) => _buildGoldPill(val, textColor: _mutedSlate)).toList(),
                          ),
                          if (profile.idealPartnerTraits.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            Text(
                              'DESIRED PARTNER QUALITIES',
                              style: AppTypography.labelSmall.copyWith(
                                color: _mutedSlate,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: profile.idealPartnerTraits.map((t) => _buildGoldPill(t, textColor: _mutedSlate)).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Bottom Spacer to ensure full scrollability above the floating button
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title, {Color? iconColor}) {
    return Row(
      children: [
        Icon(icon, color: iconColor ?? _trustGold, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: AppTypography.headingMedium.copyWith(
              fontSize: 14,
              color: _pearlGrey,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
    Color? valueColor,
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
          child: Icon(icon, size: 16, color: iconColor ?? _trustGold),
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
                  color: valueColor ?? _pearlGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactStat(String label, String value, IconData icon, {Color? iconColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor ?? _trustGold),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.bodySmall.copyWith(fontSize: 10.5, color: _mutedSlate)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: _pearlGrey,
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

  Widget _buildGoldPill(String text, {Color? textColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCardElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.borderGold, width: 0.8),
      ),
      child: Text(
        text,
        style: AppTypography.bodySmall.copyWith(
          color: textColor ?? _mutedSlate,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String _formatConciseAiExplanation(String raw, MatchProfile p) {
    final cleaned = raw.trim();
    if (cleaned.isEmpty || cleaned.length > 240) {
      final firstName = p.name.trim().split(RegExp(r'\s+')).first;
      final attach = p.attachmentStyle.isNotEmpty ? p.attachmentStyle.toLowerCase() : 'secure';
      return "$firstName's $attach attachment and calm connectivity traits directly complement your intentional builder mindset. Your shared family plans and aligned moral values form a robust foundation for a successful long-term marriage.";
    }
    return cleaned;
  }

  Widget _buildAlignmentBar(String label, int score, {Color? barColor, Color? textColor}) {
    final activeBarColor = barColor ?? _trustGold;
    final activeTextColor = textColor ?? activeBarColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodySmall.copyWith(color: _pearlGrey, fontWeight: FontWeight.w600)),
            Text(
              '$score%',
              style: AppTypography.bodySmall.copyWith(
                color: activeTextColor,
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
            valueColor: AlwaysStoppedAnimation(activeBarColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
