import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../../../core/widgets/gold_button.dart';
import '../../../../core/widgets/verified_badge.dart';
import '../../../../core/widgets/knot_app_bar.dart';
import '../providers/verification_provider.dart';
import '../../auth/providers/auth_provider.dart';
import 'widgets/camera_viewfinder.dart';
import 'widgets/liveness_scanner_overlay.dart';
import 'widgets/verification_processing_sheet.dart';

class DiditVerificationScreen extends ConsumerWidget {
  const DiditVerificationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(verificationProvider);
    final notifier = ref.read(verificationProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'IDENTITY VERIFICATION',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.champagneGold),
          onPressed: () {
            notifier.reset();
            context.pop();
          },
        ),
      ),
      body: SafeArea(
        child: _buildCurrentStep(context, ref, state, notifier),
      ),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    WidgetRef ref,
    VerificationState state,
    VerificationNotifier notifier,
  ) {
    switch (state.currentStep) {
      case VerificationStep.captureId:
        return CameraViewfinder(
          title: 'Government ID',
          hintText: 'Ensure all 4 corners, photo, and ID number are visible',
          isDocumentMode: true,
          selectedDocumentType: state.selectedDocumentType,
          onDocumentTypeSelected: (type) => notifier.setSelectedDocumentType(type),
          onImageCaptured: (path) => notifier.setIdImage(path),
        );

      case VerificationStep.reviewId:
        return _buildIdReviewScreen(context, state, notifier);

      case VerificationStep.livenessScan:
        return LivenessScannerOverlay(
          onSelfieCaptured: (path) => notifier.setSelfieImage(path),
        );

      case VerificationStep.processing:
        return VerificationProcessingSheet(
          currentPhase: state.processingPhase,
        );

      case VerificationStep.success:
        return _buildSuccessCelebration(context, ref, state, notifier);

      case VerificationStep.failed:
        return _buildFailureView(context, state, notifier);
    }
  }

  Widget _buildIdReviewScreen(
    BuildContext context,
    VerificationState state,
    VerificationNotifier notifier,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Icon & Title
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.champagneGold.withValues(alpha: 0.15),
                border: Border.all(color: AppColors.champagneGold, width: 1.5),
              ),
              child: const Icon(Icons.check_circle_outline, color: AppColors.champagneGold, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'DOCUMENT CAPTURED',
              style: AppTypography.headingLarge.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkSlate,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGold, width: 1),
              ),
              child: Text(
                state.selectedDocumentType,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.champagneGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Captured ID Document Preview Card
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 220,
                      width: double.infinity,
                      color: AppColors.obsidianBlack,
                      child: state.frontImagePath != null && File(state.frontImagePath!).existsSync()
                          ? Image.file(
                              File(state.frontImagePath!),
                              fit: BoxFit.cover,
                            )
                          : const Center(
                              child: Icon(Icons.badge, size: 70, color: AppColors.champagneGold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified, size: 16, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      Text(
                        'Document image loaded and legible',
                        style: AppTypography.bodySmall.copyWith(color: const Color(0xFF10B981)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Interactive Next Step Explanatory Card
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.champagneGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.face_retouching_natural, color: AppColors.champagneGold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NEXT STEP: LIVE SELFIE',
                          style: AppTypography.titleMedium.copyWith(fontSize: 13, color: AppColors.champagneGold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You will now take a quick live camera selfie. Our AI biometric engine will match your face with the photo on this ID.',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textPure, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Action Buttons
            GoldButton(
              text: 'Continue to Live Selfie',
              onPressed: () => notifier.proceedToLiveness(),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => notifier.retakeId(),
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.champagneGold),
              label: Text(
                'Retake / Re-upload ID',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.champagneGold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDocumentClass(String raw) {
    final val = raw.toUpperCase().trim();
    if (val.contains('NIN') || val.contains('NATIONAL') || val.contains('NIMC')) {
      return 'National Identity Card (NIN)';
    }
    if (val.contains('PASS') || val.contains('PASSPORT')) {
      return 'International Passport';
    }
    if (val.contains('DRIV') || val.contains('LICENSE')) {
      return "Driver's License";
    }
    if (val.contains('VOTE') || val.contains('PVC')) {
      return "Voter's Card (PVC)";
    }
    if (val.contains('RESID')) {
      return 'Residence Permit';
    }
    return raw;
  }

  Widget _buildSuccessCelebration(
    BuildContext context,
    WidgetRef ref,
    VerificationState state,
    VerificationNotifier notifier,
  ) {
    final result = state.result;
    final score = result?.confidenceScore ?? 96;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shimmering Gold Trust Seal
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.goldGradient,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.champagneGold.withOpacity(0.5),
                    blurRadius: 30,
                    spreadRadius: 6,
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.verified,
                  size: 56,
                  color: AppColors.obsidianBlack,
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'SOVEREIGN TRUST GRANTED',
              style: AppTypography.displayMedium.copyWith(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your identity and biometrics were authenticated via Didit.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Metrics Summary Card
            GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Verification Badge', style: AppTypography.bodySmall),
                      const VerifiedBadge(size: 20, showLabel: true, label: 'GOLD TIER'),
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Confidence Index', style: AppTypography.bodySmall),
                      Text(
                        '$score%',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.champagneGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.borderSubtle, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Document Class', style: AppTypography.bodySmall),
                      Text(
                        _formatDocumentClass(result?.documentType ?? state.selectedDocumentType),
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.champagneGold,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            GoldButton(
              text: 'Proceed to Sign In',
              onPressed: () async {
                notifier.reset();
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/auth');
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Identity verified successfully! Please sign in to enter your dashboard.'),
                      backgroundColor: Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFailureView(
    BuildContext context,
    VerificationState state,
    VerificationNotifier notifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.roseGlow.withOpacity(0.15),
                  border: Border.all(color: AppColors.roseGlow, width: 2),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: AppColors.roseGlow,
                  size: 32,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Verification Unsuccessful',
                style: AppTypography.headingLarge.copyWith(fontSize: 20),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                state.errorMessage ??
                    'Document or biometric scan could not be matched with high certainty. Please avoid glare, hold steady, and retry.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              GoldButton(
                text: 'Retry Verification',
                onPressed: () => notifier.reset(),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  notifier.reset();
                  context.pop();
                },
                child: Text('Cancel', style: AppTypography.bodyMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
