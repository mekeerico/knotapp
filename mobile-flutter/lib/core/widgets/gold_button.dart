import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;
  final Gradient? gradient;

  const GoldButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 26,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: isSecondary ? null : (gradient ?? AppColors.roseGlowGradient),
        color: isSecondary ? AppColors.darkCardElevated : null,
        border: isSecondary
            ? Border.all(color: AppColors.champagneGold.withValues(alpha: 0.5), width: 1.2)
            : null,
        boxShadow: isSecondary
            ? []
            : [
                BoxShadow(
                  color: AppColors.primaryRose.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: isLoading || onPressed == null
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isSecondary ? AppColors.champagneGold : Colors.white,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(
                          icon,
                          size: 18,
                          color: isSecondary
                              ? AppColors.champagneGold
                              : Colors.white,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        text,
                        style: AppTypography.button.copyWith(
                          color: isSecondary
                              ? AppColors.champagneGold
                              : Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
