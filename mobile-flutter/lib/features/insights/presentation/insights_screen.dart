import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../../core/widgets/verified_badge.dart';
import '../../auth/providers/auth_provider.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    final readiness = user?.readinessScore ?? 88;
    final seriousness = user?.seriousnessLevel ?? 94;
    final trust = user?.trustScore ?? 98;
    final archetype = user?.personalityArchetype ?? 'The Intentional Builder';
    final attachment = user?.attachmentStyle ?? 'Secure';
    final values = (user?.personalValues.isNotEmpty ?? false)
        ? user!.personalValues
        : ['Faith', 'Family', 'Integrity', 'Mutual Growth'];

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: const KnotAppBar(
        title: 'RELATIONSHIP INTELLIGENCE',
        showNotificationBell: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Psychological Alignment Vectors',
                style: AppTypography.displayMedium.copyWith(fontSize: 20),
              ),
              const SizedBox(height: 6),
              Text(
                'Extracted from your AI onboarding interview & verified by Knot behavioral engines.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 20),

              // 3-Metric Index Grid
              Row(
                children: [
                  Expanded(
                    child: _buildIndexCard(
                      'READINESS',
                      '$readiness%',
                      Icons.favorite_border,
                      AppColors.roseGlow,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIndexCard(
                      'SERIOUSNESS',
                      '$seriousness%',
                      Icons.lock_clock,
                      AppColors.champagneGold,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildIndexCard(
                      'TRUST SCORE',
                      '$trust%',
                      Icons.shield_outlined,
                      AppColors.emeraldVerified,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Personality Archetype Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PERSONALITY ARCHETYPE', style: AppTypography.labelLarge),
                        const VerifiedBadge(size: 16),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(archetype, style: AppTypography.headingLarge.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(
                      _getArchetypeDescription(archetype),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Attachment Style Card
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ATTACHMENT STYLE', style: AppTypography.labelLarge),
                    const SizedBox(height: 10),
                    Text(attachment, style: AppTypography.headingLarge.copyWith(fontSize: 20)),
                    const SizedBox(height: 8),
                    Text(
                      _getAttachmentDescription(attachment),
                      style: AppTypography.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Core Values Cluster
              GlassCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SACRED VALUE VECTORS', style: AppTypography.labelLarge),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: values.map((val) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.darkCardElevated,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.borderGold, width: 0.8),
                          ),
                          child: Text(
                            val,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.champagneGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndexCard(String label, String value, IconData icon, Color accentColor) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: AppTypography.headingLarge.copyWith(
              color: AppColors.textPure,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.textSubtle,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getArchetypeDescription(String arch) {
    switch (arch) {
      case 'The Grounded Romantic':
        return 'You prioritize deep emotional availability and shared life dreams, valuing stability, long-term romantic integrity, and warm daily connection.';
      case 'The Calm Connector':
        return 'You value emotional regulation and ease in conversation, managing boundaries with gentle reassurance and steady commitment timelines.';
      case 'The Loyal Partner':
        return 'You focus on long-term safety, loyalty, and dependability, building on clear mutual expectations and structural boundaries.';
      default:
        return 'You approach relationship milestones deliberately, prioritizing family values, structural boundaries, and joint growth curves.';
    }
  }

  String _getAttachmentDescription(String att) {
    switch (att) {
      case 'Anxious-Preoccupied':
        return 'High intimacy capacity with a desire for clear, steady reassurance. You flourish when partners communicate transparently and consistently.';
      case 'Dismissive-Avoidant':
        return 'High independence and self-reliance, with growing capacity to create safe, collaborative intimacy.';
      default:
        return 'Secure attachment. You express intimacy comfortably, navigate friction with calm collaborative intelligence, and recover smoothly.';
    }
  }
}
