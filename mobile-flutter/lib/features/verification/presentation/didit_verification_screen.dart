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
        child: _buildCurrentStep(context, state, notifier),
      ),
    );
  }

  Widget _buildCurrentStep(
    BuildContext context,
    VerificationState state,
    VerificationNotifier notifier,
  ) {
    switch (state.currentStep) {
      case VerificationStep.captureFront:
        return CameraViewfinder(
          title: 'Government ID (Front)',
          hintText: 'Ensure all 4 corners and photo are visible',
          isDocumentMode: true,
          onImageCaptured: (path) => notifier.setFrontImage(path),
        );

      case VerificationStep.captureBack:
        return CameraViewfinder(
          title: 'Government ID (Back)',
          hintText: 'Barcode / MRZ zone must be sharply focused',
          isDocumentMode: true,
          onImageCaptured: (path) => notifier.setBackImage(path),
          onSecondaryAction: () => notifier.skipBackImage(),
          secondaryActionText: 'Skip (Passports)',
        );

      case VerificationStep.livenessScan:
        return LivenessScannerOverlay(
          onSelfieCaptured: (path) => notifier.setSelfieImage(path),
        );

      case VerificationStep.processing:
        return VerificationProcessingSheet(
          currentPhase: state.processingPhase,
        );

      case VerificationStep.success:
        return _buildSuccessCelebration(context, state, notifier);

      case VerificationStep.failed:
        return _buildFailureView(context, state, notifier);
    }
  }

  Widget _buildSuccessCelebration(
    BuildContext context,
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
                        result?.documentType ?? 'GOVERNMENT_ID',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPure,
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
              text: 'Complete Verification',
              onPressed: () {
                notifier.reset();
                if (context.canPop()) {
                  context.pop(true);
                } else {
                  context.go('/auth');
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
