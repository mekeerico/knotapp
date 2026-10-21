import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/auto_hiding_floating_bar.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_image.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final isVerified = user?.isVerified ?? false;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: AutoHidingFloatingBar(
          bottomOffset: 0,
          topOffset: 0,
          topFloatingContent: Container(
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
                    color: AppColors.textPure,
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
                  context.go('/auth');
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
                      : AppColors.champagneGold.withOpacity(0.08),
                  border: Border.all(
                    color: isVerified
                        ? AppColors.emeraldVerified.withOpacity(0.4)
                        : AppColors.champagneGold.withOpacity(0.4),
                    width: 1.2,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isVerified
                              ? AppColors.emeraldVerified.withOpacity(0.2)
                              : AppColors.champagneGold.withOpacity(0.2),
                        ),
                        child: Icon(
                          isVerified ? Icons.verified_user : Icons.shield_outlined,
                          color: isVerified ? AppColors.emeraldVerified : AppColors.champagneGold,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  isVerified ? 'VERIFIED PROFILE' : 'UNVERIFIED PROFILE',
                                  style: AppTypography.titleMedium.copyWith(
                                    color: isVerified ? AppColors.emeraldVerified : AppColors.champagneGold,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (isVerified) ...[
                                  const SizedBox(width: 6),
                                  const VerifiedBadge(size: 18),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isVerified
                                  ? 'Biometric 1:1 match and government document certified.'
                                  : 'Complete biometric scan to unlock high-intent marriage matches.',
                              style: AppTypography.bodySmall.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      if (!isVerified)
                        GoldButton(
                          text: 'VERIFY',
                          width: 90,
                          height: 38,
                          onPressed: () => context.push('/verification'),
                        ),
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
                // Bottom spacer ensuring scroll view content never gets blocked by the floating button
                const SizedBox(height: 90),
              ],
            ),
          ),
        ),
      ),
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
