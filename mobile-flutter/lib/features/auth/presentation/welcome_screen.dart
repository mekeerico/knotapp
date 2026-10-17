import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/verified_badge.dart';
import '../providers/auth_provider.dart';

class _ShowcaseCandidate {
  final String nameAge;
  final String roleLocation;
  final String assetPath;
  final String trustScore;
  final String matchScore;
  final List<String> traits;
  final String whyMatched;

  const _ShowcaseCandidate({
    required this.nameAge,
    required this.roleLocation,
    required this.assetPath,
    required this.trustScore,
    required this.matchScore,
    required this.traits,
    required this.whyMatched,
  });
}

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();

  Timer? _initialDelayTimer;
  Timer? _autoScrollTimer;
  bool _userTookOverScroll = false;

  static const _ShowcaseCandidate _featuredCandidate = _ShowcaseCandidate(
    nameAge: 'Michael, 30',
    roleLocation: 'Engineer • San Francisco, USA',
    assetPath: 'assets/images/welcome_male.jpg',
    trustScore: 'TRUST 97%',
    matchScore: '96% Match Score',
    traits: ['✔ Family-Oriented', '✔ Secure Attachment', '✔ Marriage-Focused'],
    whyMatched:
        '"You both prioritize family traditions, share a calm conflict-resolution style, and seek marriage within 1–2 years."',
  );

  @override
  void initState() {
    super.initState();
    _startGentleAutoScroll();
  }

  void _startGentleAutoScroll() {
    // Wait briefly after launch so the user takes in the hero headline, then begin a gentle downward scroll
    _initialDelayTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted || _userTookOverScroll) return;

      // 24ms tick (~42 fps) moving 0.65px per tick = ~27px/sec smooth editorial glide
      _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 24), (timer) {
        if (!mounted || _userTookOverScroll || !_scrollController.hasClients) {
          timer.cancel();
          return;
        }
        final maxExtent = _scrollController.position.maxScrollExtent;
        final currentOffset = _scrollController.offset;
        if (currentOffset >= maxExtent) {
          timer.cancel();
          return;
        }
        _scrollController.jumpTo(
          (currentOffset + 0.65).clamp(0.0, maxExtent),
        );
      });
    });
  }

  void _stopAutoScrollOnUserTouch() {
    if (_userTookOverScroll) return;
    _userTookOverScroll = true;
    _initialDelayTimer?.cancel();
    _autoScrollTimer?.cancel();
  }

  @override
  void dispose() {
    _initialDelayTimer?.cancel();
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _navigateToAuth({required bool isRegister}) async {
    _stopAutoScrollOnUserTouch();
    await ref.read(authProvider.notifier).completeWelcome();
    if (!mounted) return;
    context.go(isRegister ? '/auth?mode=register' : '/auth');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: Stack(
        children: [
          // Subtle ambient background radial glow
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

          SafeArea(
            child: Column(
              children: [
                // Sticky Top Navigation Bar
                _buildTopNavbar(),

                // Scrollable Multi-Section Editorial Landing Content
                // Gently auto-scrolls vertically on launch and immediately yields control on touch
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _stopAutoScrollOnUserTouch(),
                    onPointerMove: (_) => _stopAutoScrollOnUserTouch(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeroSection(),
                          const SizedBox(height: 28),
                          _buildCandidateShowcaseSection(),
                          const SizedBox(height: 40),
                          _buildIntelligencePillarsSection(),
                          const SizedBox(height: 40),
                          _buildTrustArchitectureSection(),
                          const SizedBox(height: 40),
                          _buildAICoachPreviewSection(),
                          const SizedBox(height: 32),
                          _buildFooterNote(),
                        ],
                      ),
                    ),
                  ),
                ),

                // Pinned Bottom Action Bar
                _buildBottomActionBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.obsidianBlack.withValues(alpha: 0.92),
        border: const Border(
          bottom: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                'KNOT',
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 22,
                  letterSpacing: 3.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                '.',
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 24,
                  color: AppColors.champagneGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () => _navigateToAuth(isRegister: false),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Sign In',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPure,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _navigateToAuth(isRegister: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Join Registry',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.obsidianBlack,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Gold Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.champagneGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.champagneGold.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.champagneGold,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'ANTI-FRAUD  |  AI MATCHMAKING  |  HIGH-TRUST',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.champagneGold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Display Headline
        RichText(
          text: TextSpan(
            style: AppTypography.displayLarge.copyWith(
              fontSize: 34,
              height: 1.12,
              fontWeight: FontWeight.w800,
            ),
            children: [
              const TextSpan(text: 'Where\nCompatibility\nBecomes '),
              TextSpan(
                text: 'Commitment.',
                style: AppTypography.displayLarge.copyWith(
                  fontSize: 34,
                  height: 1.12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.champagneGold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'Move beyond endless swiping. KNOT combines psychological compatibility AI, biometric identity verification, and personal relationship coaching to connect individuals genuinely ready for marriage.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.55,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 22),

        // 3 Key Registry Stats
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatColumn('100%', 'Verified Users'),
              ),
              Container(width: 1, height: 32, color: AppColors.glassBorder),
              Expanded(
                child: _buildStatColumn('94%', 'Success Match Index'),
              ),
              Container(width: 1, height: 32, color: AppColors.glassBorder),
              Expanded(
                child: _buildStatColumn('0%', 'Superficial Swiping'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headingLarge.copyWith(
            color: AppColors.champagneGold,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSubtle,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCandidateShowcaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SOVEREIGN VERIFIED PROFILE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.champagneGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        _buildCinematicCandidateCard(_featuredCandidate),
      ],
    );
  }

  Widget _buildCinematicCandidateCard(_ShowcaseCandidate candidate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Discovery-Style Candidate Card with the exact Male Studio Portrait
        GestureDetector(
          onTap: () => _navigateToAuth(isRegister: true),
          child: Container(
            height: 460,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.champagneGold.withValues(alpha: 0.45),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 24,
                  spreadRadius: 4,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(27),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Exact Male Studio Portrait Image
                  Image.asset(
                    candidate.assetPath,
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),

                  // 2. Dark Gradient Overlay for Text Readability (Matches CandidateCard)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.95),
                        ],
                        stops: const [0.0, 0.35, 0.7, 1.0],
                      ),
                    ),
                  ),

                  // 3. Top Row: Match Score Pill & Gold Verified Badge (Matches CandidateCard)
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Closest Match Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.obsidianBlack.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.champagneGold,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: AppColors.roseGlow,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '96% CLOSEST MATCH',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.champagneGold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Sovereign Gold Verified Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.obsidianBlack.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: const VerifiedBadge(
                            size: 16,
                            showLabel: true,
                            label: 'GOLD',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 4. Bottom Profile Details Overlay (Matches CandidateCard)
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Full-Width Name, Age & Verified Badge
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'MICHAEL, 30',
                                style: AppTypography.headingLarge.copyWith(
                                  fontSize: 24,
                                  color: AppColors.textPure,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const VerifiedBadge(size: 20),
                          ],
                        ),
                        const SizedBox(height: 6),

                        // Occupation Row
                        Row(
                          children: [
                            const Icon(
                              Icons.work_outline,
                              size: 15,
                              color: AppColors.champagneGold,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Principal Engineer',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Location Row
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'San Francisco, USA',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Archetype & Marriage Timeline Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildMiniChip(
                              'The Strategic Visionary',
                              Icons.psychology_outlined,
                            ),
                            _buildMiniChip(
                              'Within 18 months',
                              Icons.access_time,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Tap to view full compatibility hint
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'View Psychological Compatibility & Vows',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.champagneGold,
                                fontSize: 11,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 13,
                              color: AppColors.champagneGold,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // 5. Current Discovery Action Buttons Row (X, Star, Love)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildDiscoveryActionButton(
              icon: Icons.close,
              color: AppColors.textSubtle,
              size: 52,
              onTap: () => _navigateToAuth(isRegister: false),
            ),
            _buildDiscoveryActionButton(
              icon: Icons.star,
              color: AppColors.champagneGold,
              size: 64,
              onTap: () => _navigateToAuth(isRegister: true),
            ),
            _buildDiscoveryActionButton(
              icon: Icons.favorite,
              color: AppColors.roseGlow,
              size: 52,
              onTap: () => _navigateToAuth(isRegister: true),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 6. "Why You Matched" AI Explanation Box
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'WHY YOU MATCHED (AI COMPATIBILITY)',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.champagneGold,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                candidate.whyMatched,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.champagneGold),
          const SizedBox(width: 5),
          Text(
            text,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textPure,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscoveryActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.darkSlate,
          border: Border.all(
            color: color.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.25),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.45,
        ),
      ),
    );
  }

  Widget _buildIntelligencePillarsSection() {
    final pillars = [
      {
        'icon': Icons.psychology_outlined,
        'title': 'Compatibility AI',
        'desc':
            'Matches based on values, attachment styles, communication patterns, and marriage readiness.',
      },
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Identity Verification',
        'desc':
            'Biometric live selfie and government ID verification eliminate fake profiles and catfishing.',
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'title': 'AI Relationship Coach',
        'desc':
            '24/7 personal guidance for deeper conversations, conflict resolution, and emotional connection.',
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Anti-Fraud Engine',
        'desc':
            'Continuous behavioral analysis and duplicate photo detection protect the integrity of every match.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELATIONSHIP INTELLIGENCE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.champagneGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Relationship Intelligence Technology',
          style: AppTypography.headingLarge.copyWith(
            fontSize: 24,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We replaced addictive swiping algorithms with deep psychological alignment and impenetrable security.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 18),
        ...pillars.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassCard(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: AppColors.champagneGold.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      p['icon'] as IconData,
                      color: AppColors.champagneGold,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p['title'] as String,
                          style: AppTypography.headingMedium.copyWith(
                            fontSize: 16,
                            color: AppColors.textPure,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['desc'] as String,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustArchitectureSection() {
    final checks = [
      'Government ID Verified',
      'Liveness Selfie Verified',
      'Phone & Account Authenticity',
      'Clean Communication History',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.emeraldSuccess.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.emeraldSuccess.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            'ZERO-TOLERANCE SECURITY',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.emeraldSuccess,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'An Impenetrable Trust Architecture.',
          style: AppTypography.headingLarge.copyWith(
            fontSize: 24,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Traditional dating apps profit from your prolonged search and ignore fraudulent accounts. KNOT enforces mandatory multi-step identity verification before any user can interact.',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),

        // 0% Catfishing & Duplicate Elimination Mini Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '0% Catfishing',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.champagneGold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live facial liveness & ID cross-matching.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Anti-Scam AI',
                      style: AppTypography.headingMedium.copyWith(
                        color: AppColors.champagneGold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Document expiry & biometric age audit.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // KNOT Trust Profile (98%) Card
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.emeraldSuccess.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.emeraldSuccess.withValues(alpha: 0.4),
                  ),
                ),
                child: const Icon(
                  Icons.verified_user,
                  color: AppColors.emeraldSuccess,
                  size: 28,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'KNOT Trust Profile',
                style: AppTypography.headingMedium.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 2),
              Text(
                'Sample Verified Member Status',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSubtle,
                  fontSize: 11.5,
                ),
              ),
              const SizedBox(height: 16),
              ...checks.map(
                (label) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        label,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPure,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '✔ PASSED',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.emeraldSuccess,
                          fontWeight: FontWeight.w800,
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OVERALL TRUST SCORE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSubtle,
                      fontSize: 10.5,
                    ),
                  ),
                  Text(
                    '98%',
                    style: AppTypography.headingLarge.copyWith(
                      color: AppColors.champagneGold,
                      fontSize: 22,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAICoachPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.royalPurple.withValues(alpha: 0.45),
            const Color(0xFF121622),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.champagneGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'MEET YOUR AI RELATIONSHIP COACH',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.champagneGold,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Never Run Out of Meaningful Things to Say.',
            style: AppTypography.headingLarge.copyWith(
              fontSize: 22,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Whether you need a tailored icebreaker, advice on navigating serious marriage topics, or feedback on your communication style, your private AI Coach is built into every step.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 16),

          // Simulated Coach Conversation Bubble
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.champagneGold.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'AI COACH ICEBREAKER',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.champagneGold,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '"Since you both place family traditions and faith at the center of your future home, ask what childhood family tradition they are most excited to carry into their own marriage."',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.champagneGold,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Center(
      child: Column(
        children: [
          Text(
            'KNOT. — Where True Relationship Leads to Vow',
            style: AppTypography.labelLarge.copyWith(
              color: AppColors.champagneGold,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Protected by Didit Sovereign KYC & Biometric Identity Verification.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSubtle,
              fontSize: 10.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: AppColors.obsidianBlack.withValues(alpha: 0.96),
        border: const Border(
          top: BorderSide(color: AppColors.glassBorder, width: 0.8),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GoldButton(
            text: 'Join the Sovereign Registry',
            onPressed: () => _navigateToAuth(isRegister: true),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _navigateToAuth(isRegister: false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12.5,
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign In',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.champagneGold,
                        fontWeight: FontWeight.w800,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
