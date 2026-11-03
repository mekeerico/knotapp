import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/auto_hiding_floating_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_image.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _headerVisible = true;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isVerified = user?.isVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (_headerVisible) {
            setState(() => _headerVisible = false);
          }
        },
        onPointerUp: (_) {
          if (!_headerVisible) {
            setState(() => _headerVisible = true);
          }
        },
        onPointerCancel: (_) {
          if (!_headerVisible) {
            setState(() => _headerVisible = true);
          }
        },
        child: SafeArea(
          child: AutoHidingFloatingBar(
            bottomOffset: 0,
            topOffset: 0,
            topFloatingContent: AnimatedSlide(
              offset: _headerVisible ? Offset.zero : const Offset(0, -0.4),
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _headerVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.obsidianBlack,
                        AppColors.obsidianBlack.withOpacity(0.95),
                        AppColors.obsidianBlack.withOpacity(0.72),
                        Colors.transparent,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.55, 0.85, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.only(
                    top: 14,
                    bottom: 18,
                    left: 20,
                    right: 20,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 40),
                      Text(
                        'SOVEREIGN IDENTITY',
                        style: AppTypography.headingMedium.copyWith(
                          letterSpacing: 1.5,
                          color: const Color(0xFFD1D5DC),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded, color: AppColors.champagneGold, size: 22),
                        onPressed: () => context.push('/partner-preferences'),
                        tooltip: 'Partner Match Preferences',
                      ),
                    ],
                  ),
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
            padding: const EdgeInsets.only(
              left: 20,
              right: 20,
              top: 14,
              bottom: 16,
            ),
            child: GestureDetector(
              onTap: () async {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/auth?mode=login');
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.roseGlowGradient,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryRose.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.logout, color: Colors.white, size: 18),
                  ],
                ),
              ),
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 62, bottom: 12),
            child: Column(
              children: [
                // User Avatar & Name Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.champagneGold, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.champagneGold.withOpacity(0.3),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: KnotImage(
                              imageUrl: user?.primaryPhoto,
                              width: 96,
                              height: 96,
                              isCircle: true,
                            ),
                          ),
                          if (isVerified)
                            const Positioned(
                              bottom: 0,
                              right: 0,
                              child: VerifiedBadge(size: 26),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.fullName ?? 'Sovereign Candidate',
                        style: AppTypography.displayMedium.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${user?.occupation.isNotEmpty ?? false ? user!.occupation : "Professional"} • ${user?.residenceCity.isNotEmpty ?? false ? user!.residenceCity : "Global Registry"}',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Didit KYC Verification Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  backgroundColor: isVerified
                      ? AppColors.emeraldVerified.withOpacity(0.08)
                      : Colors.amber.withOpacity(0.10),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.emeraldVerified.withOpacity(0.4)
                        : Colors.amber.withOpacity(0.4),
                    width: 1.2,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isVerified
                                  ? AppColors.emeraldVerified.withOpacity(0.2)
                                  : Colors.amber.withOpacity(0.2),
                              border: Border.all(
                                color: isVerified
                                    ? AppColors.emeraldVerified.withOpacity(0.4)
                                    : Colors.amber.withOpacity(0.4),
                              ),
                            ),
                            child: Icon(
                              isVerified ? Icons.verified_user : Icons.shield_outlined,
                              color: isVerified ? AppColors.emeraldVerified : Colors.amber,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        isVerified
                                            ? 'VERIFIED PROFILE'
                                            : 'UNVERIFIED PROFILE — HIDDEN FROM REGISTRY',
                                        style: AppTypography.titleMedium.copyWith(
                                          color: isVerified ? AppColors.emeraldVerified : Colors.amber.shade300,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ),
                                    if (isVerified) ...[
                                      const SizedBox(width: 6),
                                      const VerifiedBadge(size: 18),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  isVerified
                                      ? 'Biometric 1:1 match and government document certified.'
                                      : '⚠️ Your profile is currently hidden from other members. You cannot be matched to any candidates until you complete biometric verification.',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 12,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (!isVerified) ...[
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFD4AF37),
                                  Color(0xFFF3E5AB),
                                  Color(0xFFAA7C11),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFD4AF37).withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () => context.push('/verification'),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.verified_user_rounded,
                                        color: Colors.black,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'VERIFY NOW',
                                        style: AppTypography.labelLarge.copyWith(
                                          color: Colors.black,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 11,
                                          letterSpacing: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Profile Actions Menu
                _buildMenuItem(
                  context,
                  title: 'Partner Match Preferences',
                  icon: Icons.tune_rounded,
                  onTap: () => context.push('/partner-preferences'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Edit Your Profile',
                  icon: Icons.edit_note,
                  onTap: () => context.push('/edit-profile'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Manage Your Photos',
                  icon: Icons.photo_library_outlined,
                  onTap: () => context.push('/manage-photos'),
                ),
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Upgrade',
                  icon: Icons.workspace_premium,
                  onTap: () => context.push('/paywall'),
                ),
                if (!isVerified) ...[
                  const SizedBox(height: 12),
                  _buildMenuItem(
                    context,
                    title: 'Verify Your Identity',
                    icon: Icons.verified_user_outlined,
                    onTap: () => context.push('/verification'),
                  ),
                ],
                const SizedBox(height: 12),
                _buildMenuItem(
                  context,
                  title: 'Support & Enquiry',
                  icon: Icons.support_agent_rounded,
                  onTap: () => _showSupportEnquiryModal(context, user),
                ),
                // Bottom spacer ensuring scroll view content never gets blocked by the floating button
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  void _showSupportEnquiryModal(BuildContext context, dynamic user) {
    final categories = [
      'General Enquiry',
      'Account & Verification',
      'Subscription & Billing',
      'Matchmaking & AI Coach',
      'Technical Issue',
      'Safety & Report',
      'Other',
    ];
    String selectedCategory = categories.first;
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    bool isSubmitting = false;
    List<dynamic> myTickets = [];
    bool loadingTickets = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.obsidianBlack,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            if (loadingTickets) {
              loadingTickets = false;
              ref.read(dioProvider).get(ApiEndpoints.mySupport).then((res) {
                if (ctx.mounted && res.data is List) {
                  setModalState(() {
                    myTickets = res.data as List<dynamic>;
                  });
                }
              }).catchError((_) {});
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.support_agent_rounded,
                              color: AppColors.champagneGold,
                              size: 24,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Support & Enquiry',
                              style: AppTypography.headingMedium,
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.textSubtle),
                          onPressed: () => Navigator.of(modalCtx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Send an enquiry or support request directly to the KNOT Concierge & Admin team.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textSubtle),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'CATEGORY OF ENQUIRY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.champagneGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          dropdownColor: const Color(0xFF16161D),
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.champagneGold),
                          style: AppTypography.bodyMedium.copyWith(color: Colors.white),
                          items: categories
                              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setModalState(() => selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'SUBJECT',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.champagneGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: subjectCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Brief summary of your enquiry...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.champagneGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'MESSAGE',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.champagneGold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Describe your question or issue in detail...',
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.05),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.champagneGold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    GoldButton(
                      text: 'Submit Enquiry',
                      isLoading: isSubmitting,
                      onPressed: () async {
                        final subject = subjectCtrl.text.trim();
                        final message = messageCtrl.text.trim();
                        if (subject.isEmpty || message.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enter both a subject and message.'),
                              backgroundColor: AppColors.errorRed,
                            ),
                          );
                          return;
                        }
                        setModalState(() => isSubmitting = true);
                        try {
                          await ref.read(dioProvider).post(
                            ApiEndpoints.support,
                            data: {
                              'userId': user?.id,
                              'userEmail': user?.email,
                              'userName': user?.firstName,
                              'category': selectedCategory,
                              'subject': subject,
                              'message': message,
                            },
                          );
                          if (modalCtx.mounted) {
                            Navigator.of(modalCtx).pop();
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Your enquiry has been sent to the Admin team!'),
                                backgroundColor: Color(0xFF10B981),
                              ),
                            );
                          }
                        } catch (e) {
                          setModalState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Failed to submit enquiry. Please try again.'),
                                backgroundColor: AppColors.errorRed,
                              ),
                            );
                          }
                        }
                      },
                    ),
                    if (myTickets.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Divider(color: Colors.white12),
                      const SizedBox(height: 12),
                      Text(
                        'YOUR PREVIOUS ENQUIRIES',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.champagneGold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...myTickets.take(5).map((t) {
                        final status = (t['status'] ?? 'OPEN').toString();
                        final adminResponse = t['adminResponse']?.toString();
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      t['subject']?.toString() ?? '',
                                      style: AppTypography.titleMedium.copyWith(fontSize: 13),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: status == 'RESPONDED'
                                          ? const Color(0xFF10B981).withOpacity(0.18)
                                          : AppColors.champagneGold.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: status == 'RESPONDED'
                                            ? const Color(0xFF10B981)
                                            : AppColors.champagneGold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                t['category']?.toString() ?? '',
                                style: AppTypography.bodySmall.copyWith(
                                  fontSize: 11,
                                  color: AppColors.textSubtle,
                                ),
                              ),
                              if (adminResponse != null && adminResponse.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.champagneGold.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.champagneGold.withOpacity(0.25)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Admin Response:',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.champagneGold,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        adminResponse,
                                        style: AppTypography.bodySmall.copyWith(color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Icon(icon, color: AppColors.champagneGold, size: 22),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.titleMedium.copyWith(fontSize: 14),
            ),
          ),
          const Align(
            alignment: Alignment.centerRight,
            child: Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.textSubtle),
          ),
        ],
      ),
    );
  }
}
