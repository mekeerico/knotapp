import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/glass_card.dart';
import '../../providers/verification_provider.dart';

class VerificationProcessingSheet extends StatelessWidget {
  final ProcessingPhase currentPhase;

  const VerificationProcessingSheet({
    super.key,
    required this.currentPhase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidianBlack,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Center(
        child: GlassCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rotating Luxury Gold Spinner
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.champagneGold.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.champagneGold),
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'DIDIT AI VERIFICATION',
                style: AppTypography.headingMedium.copyWith(
                  letterSpacing: 2.0,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Establishing cryptographic proof of identity & biometric authenticity.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Step 1: Document Authenticity
              _buildStepRow(
                title: 'Analyzing Document Legitimacy',
                subtitle: 'OCR parsing & fraud tampering scan',
                isActive: currentPhase == ProcessingPhase.analyzingDocument,
                isCompleted: currentPhase.index > ProcessingPhase.analyzingDocument.index,
              ),
              const SizedBox(height: 16),

              // Step 2: Liveness Validation
              _buildStepRow(
                title: 'Passive Liveness Verification',
                subtitle: 'Confirming live 3D human presence',
                isActive: currentPhase == ProcessingPhase.validatingLiveness,
                isCompleted: currentPhase.index > ProcessingPhase.validatingLiveness.index,
              ),
              const SizedBox(height: 16),

              // Step 3: Biometric Face Match
              _buildStepRow(
                title: '1:1 Biometric Face Match',
                subtitle: 'Cross-verifying selfie against government photo',
                isActive: currentPhase == ProcessingPhase.runningFaceMatch,
                isCompleted: currentPhase.index > ProcessingPhase.runningFaceMatch.index,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted
                ? AppColors.emeraldVerified
                : isActive
                    ? AppColors.champagneGold.withOpacity(0.2)
                    : AppColors.darkCardElevated,
            border: Border.all(
              color: isCompleted
                  ? AppColors.emeraldVerified
                  : isActive
                      ? AppColors.champagneGold
                      : AppColors.borderSubtle,
              width: 1.5,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : isActive
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.champagneGold),
                        ),
                      )
                    : const Icon(Icons.circle, size: 8, color: AppColors.textSubtle),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleMedium.copyWith(
                  fontSize: 14,
                  color: isActive || isCompleted
                      ? AppColors.textPure
                      : AppColors.textSubtle,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: isCompleted ? AppColors.emeraldVerified : AppColors.textSubtle,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
