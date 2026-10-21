import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/auth_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _trustSectionKey = GlobalKey();

  Timer? _initialDelayTimer;
  Timer? _autoScrollTimer;
  bool _userTookOverScroll = false;

  // Exact Web Palette (Obsidian Black, Champagne Gold, Emerald Green, Velvet Rose)
  static const Color _webGold = Color(0xFFD4AF37);
  static const Color _webGoldLight = Color(0xFFF3E5AB);
  static const Color _webGoldDark = Color(0xFFAA7C11);
  static const Color _webEmerald = Color(0xFF10B981);
  static const Color _webRose = Color(0xFFE27D8D);
  static const Color _webDeepPurple = Color(0xFF2D1B4E);
  static const Color _webObsidian = Color(0xFF0A0E14);
  static const Color _webOffWhite = Color(0xFFF5F5F1);
  static const Color _webSlateMuted = Color(0xFF94A3B8);

  static const LinearGradient _webGoldGradient = LinearGradient(
    colors: [_webGold, _webGoldLight, _webGoldDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient _webRoseGlowGradient = LinearGradient(
    colors: [_webRose, _webDeepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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

      // Smooth editorial scroll glide down the page
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

  void _scrollToTrustSection() {
    _stopAutoScrollOnUserTouch();
    final targetContext = _trustSectionKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _webObsidian,
      body: Stack(
        children: [
          // Ambient background radial purple/gold glow (Matches web .brand-bg-glow & orb-pulse)
          Positioned(
            top: -100,
            left: -60,
            right: -60,
            child: IgnorePointer(
              child: Container(
                height: 380,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _webDeepPurple.withValues(alpha: 0.45),
                      _webGold.withValues(alpha: 0.06),
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
                // 1. Sticky Top Navigation Bar (Matches Web Header)
                _buildTopNavbar(),

                // 2. Scrollable Multi-Section Landing Content (Matches Web Sections)
                Expanded(
                  child: Listener(
                    onPointerDown: (_) => _stopAutoScrollOnUserTouch(),
                    onPointerMove: (_) => _stopAutoScrollOnUserTouch(),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hero Section
                          _buildHeroSection(),
                          const SizedBox(height: 36),

                          // Cinematic Interactive Core Visual Mockup (Matches Web Gabriel/Michael Card)
                          _buildCandidateShowcaseSection(),
                          const SizedBox(height: 48),

                          // Feature Section (Deep Intelligence Platforms)
                          _buildIntelligencePillarsSection(),
                          const SizedBox(height: 48),

                          // Trust Architecture Details (Zero-Tolerance Security)
                          _buildTrustArchitectureSection(),
                          const SizedBox(height: 48),

                          // AI Relationship Coach Showcase
                          _buildAICoachPreviewSection(),
                          const SizedBox(height: 44),

                          // Web-Aligned Footer
                          _buildFooterNote(),
                        ],
                      ),
                    ),
                  ),
                ),

                // 3. Pinned Bottom Action Bar
                _buildBottomActionBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top Navbar (Matches Web Header)
  // ---------------------------------------------------------------------------
  Widget _buildTopNavbar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _webObsidian.withValues(alpha: 0.85),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo KNOT.
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KNOT',
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 22,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.w900,
                  color: _webOffWhite,
                ),
              ),
              Text(
                '.',
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 24,
                  color: _webGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          // Actions: Sign In & Join Registry
          Row(
            children: [
              TextButton(
                onPressed: () => _navigateToAuth(isRegister: false),
                style: TextButton.styleFrom(
                  foregroundColor: _webSlateMuted,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                child: Text(
                  'Sign In',
                  style: AppTypography.labelLarge.copyWith(
                    color: _webOffWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _navigateToAuth(isRegister: true),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8.5),
                  decoration: BoxDecoration(
                    gradient: _webRoseGlowGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _webRose.withValues(alpha: 0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Join Registry',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
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

  // ---------------------------------------------------------------------------
  // Hero Section (Matches Web Hero)
  // ---------------------------------------------------------------------------
  Widget _buildHeroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Anti-Fraud Pill (Matches Web)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: _webGold,
                size: 13,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  'ANTI-FRAUD | AI MATCHMAKING | HIGH-TRUST',
                  style: AppTypography.labelSmall.copyWith(
                    color: _webGold,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Display Headline: "Where Compatibility Becomes Commitment."
        RichText(
          text: TextSpan(
            style: AppTypography.displayLarge.copyWith(
              fontSize: 34,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: _webOffWhite,
            ),
            children: [
              const TextSpan(text: 'Where Compatibility\nBecomes '),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => _webGoldGradient.createShader(bounds),
                  child: Text(
                    'Commitment.',
                    style: AppTypography.displayLarge.copyWith(
                      fontSize: 34,
                      height: 1.15,
                      fontWeight: FontWeight.w900,
                      color: _webGold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Subtitle (Matches Web)
        Text(
          "KNOT is the world's most trusted relationship intelligence ecosystem built exclusively for verified singles seeking marriage and permanent partnership. No shallow swipes. No superficial games. Just real love.",
          style: AppTypography.bodyMedium.copyWith(
            color: _webSlateMuted,
            height: 1.55,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 24),

        // Hero CTA Buttons (Matches Web)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => _navigateToAuth(isRegister: true),
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: _webRoseGlowGradient,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _webRose.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Begin AI Guided Interview',
                        style: AppTypography.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 15,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _scrollToTrustSection,
          child: Container(
            width: double.infinity,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            child: Center(
              child: Text(
                'Our Verification System',
                style: AppTypography.labelLarge.copyWith(
                  color: _webOffWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // 3 Key Registry Stats (Matches Web 100%, 94%, 0%)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatColumn('100%', 'VERIFIED USERS', isGold: false),
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(
                child: _buildStatColumn('94%', 'SUCCESS MATCH INDEX', isGold: true),
              ),
              Container(width: 1, height: 32, color: Colors.white.withValues(alpha: 0.08)),
              Expanded(
                child: _buildStatColumn('0%', 'SUPERFICIAL SWIPING', isGold: false),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String value, String label, {required bool isGold}) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.headingLarge.copyWith(
            color: isGold ? _webGold : Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: const Color(0xFF6B7280),
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Core Visual Mockup (Matches Web Interactive Gabriel/Michael Card)
  // ---------------------------------------------------------------------------
  Widget _buildCandidateShowcaseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Subtitle
        Text(
          'CURATED INTENTIONAL MATCHES',
          style: AppTypography.labelSmall.copyWith(
            color: _webGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),

        // Interactive Glass Card Mockup (Matches Web layout)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xB3121721),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.10),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 28,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Frame with Verified Badge & Match Score
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  height: 380,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Photo
                      Image.asset(
                        'assets/images/welcome_male.jpg',
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                      ),

                      // Top-right Trust Badge (Matches Web .trust-badge)
                      Positioned(
                        top: 14,
                        right: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: _webEmerald.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _webEmerald.withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified_user,
                                color: _webEmerald,
                                size: 13,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                'ID & Selfie Verified',
                                style: AppTypography.labelSmall.copyWith(
                                  color: _webEmerald,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Bottom Gradient & Candidate Details
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.90),
                              ],
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Name & Subtitle
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Gabriel, 29',
                                    style: AppTypography.headingLarge.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Architect • Intentional Builder',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: _webGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),

                              // Match Score Pill (Matches Web)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _webGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _webGold,
                                    width: 1.2,
                                  ),
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'MATCH SCORE',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: const Color(0xFFD1D5DB),
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: 1),
                                    Text(
                                      '96%',
                                      style: AppTypography.headingMedium.copyWith(
                                        color: _webGold,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3 Trait Chips (Matches Web)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildWebChip('✔ Family-Oriented', isGold: false),
                  _buildWebChip('✔ Secure Attachment', isGold: true),
                  _buildWebChip('✔ Marriage-Focused', isGold: false),
                ],
              ),
              const SizedBox(height: 14),

              // "Why You Matched" Box (Matches Web)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.smart_toy_outlined,
                          color: _webGold,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Why You Matched',
                          style: AppTypography.labelSmall.copyWith(
                            color: _webGold,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"Both value career milestones and solid family foundations. Your complementary conflict-resolution styles (Secure-Collaborative) suggest high capability for long-term marital success."',
                      style: AppTypography.bodySmall.copyWith(
                        color: _webSlateMuted,
                        height: 1.45,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWebChip(String label, {required bool isGold}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: isGold
            ? _webDeepPurple.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isGold
              ? _webGold.withValues(alpha: 0.30)
              : Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: isGold ? _webGold : const Color(0xFFD1D5DB),
          fontSize: 11,
          fontWeight: isGold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Relationship Intelligence Technology (Matches Web 4 Pillars)
  // ---------------------------------------------------------------------------
  Widget _buildIntelligencePillarsSection() {
    final pillars = [
      {
        'icon': Icons.handshake_outlined,
        'title': 'Compatibility AI',
        'desc':
            'Calculates values, lifestyle alignments, attachment archetypes, and marriage timelines. We match on psychological depth, not surface appearances.',
        'color': _webGold,
      },
      {
        'icon': Icons.verified_user_outlined,
        'title': 'Identity Verification',
        'desc':
            'Dual government ID and real-time biometric selfie verification. Keeps 100% of romance scammers, catfishers, and malicious bad actors out.',
        'color': _webEmerald,
      },
      {
        'icon': Icons.smart_toy_outlined,
        'title': 'AI Relationship Coach',
        'desc':
            'An empathetic relationship therapist in your pocket. Offers icebreakers, conversation analysis, first date strategies, and marital readiness checkpoints.',
        'color': _webRose,
      },
      {
        'icon': Icons.gpp_maybe_outlined,
        'title': 'Anti-Fraud Engine',
        'desc':
            'Real-time conversation safety shields monitor indicators of financial coercion, catfish speech patterns, and manipulation to protect your emotional safety.',
        'color': const Color(0xFFF87171),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RELATIONSHIP INTELLIGENCE',
          style: AppTypography.labelSmall.copyWith(
            color: _webGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Relationship Intelligence Technology',
          style: AppTypography.headingLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Our four foundational layers engineered specifically to ensure maximum security, safety, and compatibility.',
          style: AppTypography.bodyMedium.copyWith(
            color: _webSlateMuted,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 20),

        ...pillars.map(
          (p) {
            final color = p['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xB3121721),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: color.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Icon(
                        p['icon'] as IconData,
                        color: color,
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
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            p['desc'] as String,
                            style: AppTypography.bodySmall.copyWith(
                              color: _webSlateMuted,
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
            );
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Trust Architecture Details (Matches Web Trust Section)
  // ---------------------------------------------------------------------------
  Widget _buildTrustArchitectureSection() {
    final checks = [
      'Government ID Verified',
      'Liveness Selfie Verified',
      'Phone & Account Authenticity',
      'Clean Communication History',
    ];

    return Column(
      key: _trustSectionKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline with Emerald Accent (Matches Web)
        RichText(
          text: TextSpan(
            style: AppTypography.headingLarge.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              height: 1.25,
              color: Colors.white,
            ),
            children: const [
              TextSpan(text: 'An Impenetrable Network\nof '),
              TextSpan(
                text: 'Verified Real Humans.',
                style: TextStyle(color: _webEmerald),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Casual dating apps optimize for bot density, fake profiles, and scams to increase endless swiping loops. At KNOT, we completely removed scams. Every member undergoes strict, AI-validated identity screening before interacting with the registry.',
          style: AppTypography.bodyMedium.copyWith(
            color: _webSlateMuted,
            fontSize: 13.5,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 18),

        // 0% Catfishing & Duplicate Elimination Cards (Matches Web)
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _webEmerald.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.how_to_reg_outlined,
                        color: _webEmerald,
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '0% Catfishing',
                      style: AppTypography.headingMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Biometric face-matching guarantees profiles correspond to actual human images.',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: 11,
                        height: 1.4,
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
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _webEmerald.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.security,
                        color: _webEmerald,
                        size: 19,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Duplicate Elimination',
                      style: AppTypography.headingMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'One unique verified account per SSN/ID parameters to restrict fake loops.',
                      style: AppTypography.bodySmall.copyWith(
                        color: const Color(0xFF6B7280),
                        fontSize: 11,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // KNOT Trust Profile Card (Matches Web)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xB3121721),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _webEmerald.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.verified_user,
                        color: _webEmerald,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'KNOT TRUST PROFILE',
                        style: AppTypography.labelSmall.copyWith(
                          color: _webEmerald,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '98%',
                    style: AppTypography.headingLarge.copyWith(
                      color: _webEmerald,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4 Verification Lines (Matches Web)
              ...checks.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item,
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFFD1D5DB),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: _webEmerald,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'This trust profile resides on our high-performance ledger, preventing malicious duplicates and fake identities.',
                style: AppTypography.bodySmall.copyWith(
                  color: const Color(0xFF6B7280),
                  fontSize: 11,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // AI Relationship Coach Showcase (Matches Web Coach Section)
  // ---------------------------------------------------------------------------
  Widget _buildAICoachPreviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI RELATIONSHIP COACH',
          style: AppTypography.labelSmall.copyWith(
            color: _webGold,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Meet Your Relationship Coach',
          style: AppTypography.headingLarge.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Not sure how to break the ice or navigate differences? KNOT's real-time AI Coach assists couples in communicating securely and with high emotional intelligence.",
          style: AppTypography.bodyMedium.copyWith(
            color: _webSlateMuted,
            fontSize: 13.5,
          ),
        ),
        const SizedBox(height: 20),

        // Dual Presentation Card (Empathetic Intelligence + Chat Preview)
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xB3121721),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Banner: Empathetic Intelligence
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _webDeepPurple.withValues(alpha: 0.25),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _webGold.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _webGold.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.smart_toy_outlined,
                        color: _webGold,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Empathetic Intelligence',
                      style: AppTypography.headingLarge.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Our coach does not just spit generic advice. It evaluates both user's profile dimensions, attachment style dynamics, and conversational milestones to offer highly tailored guidance.",
                      style: AppTypography.bodySmall.copyWith(
                        color: _webSlateMuted,
                        height: 1.45,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: _webGold,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Assisted 12,000+ matches to commitment',
                          style: AppTypography.bodySmall.copyWith(
                            color: const Color(0xFF6B7280),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bottom Simulated Chat View (Matches Web Chat Mockup)
              Container(
                padding: const EdgeInsets.all(18),
                color: Colors.black.withValues(alpha: 0.5),
                child: Column(
                  children: [
                    // AI Message 1
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _webGold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _webGold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: _webGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: const Text(
                              '"I noticed both of you value travel and family traditions. Would you like a prompt to start the conversation?"',
                              style: TextStyle(
                                color: Color(0xFFD1D5DB),
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // User Message (ME)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.only(left: 40),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _webRose.withValues(alpha: 0.15),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: _webRose.withValues(alpha: 0.25),
                              ),
                            ),
                            child: const Text(
                              '"Yes, please suggest an elegant icebreaker."',
                              style: TextStyle(
                                color: _webOffWhite,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: _webRose,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'ME',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // AI Message 2 (Custom Icebreaker)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _webGold.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _webGold.withValues(alpha: 0.25),
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'AI',
                              style: TextStyle(
                                color: _webGold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                                bottomRight: Radius.circular(16),
                              ),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  '"Here is a custom icebreaker based on your high values alignment:"',
                                  style: TextStyle(
                                    color: Color(0xFFD1D5DB),
                                    fontSize: 11.5,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '"Since you both love exploring historical towns, what is one memory from a childhood trip that inspired your current love for history?"',
                                  style: TextStyle(
                                    color: _webGold,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
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
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Web-Aligned Footer
  // ---------------------------------------------------------------------------
  Widget _buildFooterNote() {
    return Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'KNOT',
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                  color: Colors.white,
                ),
              ),
              Text(
                '.',
                style: AppTypography.headingLarge.copyWith(
                  fontSize: 20,
                  color: _webGold,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '© 2026 KNOT AI Relationship Systems.',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Terms of Service  •  Privacy Policy  •  Community Guidelines',
            style: AppTypography.bodySmall.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Pinned Bottom Action Bar
  // ---------------------------------------------------------------------------
  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: _webObsidian.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary Action Button (Matches Web rose-glow-btn)
          GestureDetector(
            onTap: () => _navigateToAuth(isRegister: true),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                gradient: _webRoseGlowGradient,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: _webRose.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Begin AI Guided Interview',
                    style: AppTypography.labelLarge.copyWith(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 17,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Secondary Sign In Link
          GestureDetector(
            onTap: () => _navigateToAuth(isRegister: false),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.bodySmall.copyWith(
                    color: _webSlateMuted,
                    fontSize: 12.5,
                  ),
                  children: const [
                    TextSpan(text: 'Already have an account? '),
                    TextSpan(
                      text: 'Sign In',
                      style: TextStyle(
                        color: _webGold,
                        fontWeight: FontWeight.w800,
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
