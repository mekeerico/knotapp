import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class VerifiedBadge extends StatefulWidget {
  final double size;
  final bool showLabel;
  final String label;

  const VerifiedBadge({
    super.key,
    this.size = 18,
    this.showLabel = false,
    this.label = 'VERIFIED',
  });

  @override
  State<VerifiedBadge> createState() => _VerifiedBadgeState();
}

class _VerifiedBadgeState extends State<VerifiedBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final shimmerValue = _shimmerController.value;
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  transform: GradientRotation(shimmerValue * 6.28),
                  colors: const [
                    AppColors.goldLight,
                    AppColors.champagneGold,
                    AppColors.goldDark,
                    AppColors.goldLight,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.champagneGold.withOpacity(0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.check,
                  size: widget.size * 0.65,
                  color: AppColors.obsidianBlack,
                ),
              ),
            ),
            if (widget.showLabel) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.champagneGold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: AppColors.champagneGold.withOpacity(0.4),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  widget.label,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.champagneGold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                    fontSize: widget.size * 0.55,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
