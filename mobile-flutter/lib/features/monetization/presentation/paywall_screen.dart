import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  int _selectedTier = 1; // 0: Essential, 1: Gold Sovereign, 2: Platinum Vows

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'SOVEREIGN VIP TIERS',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.champagneGold),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              Text(
                'Unlock Sovereign Privileges',
                style: AppTypography.displayMedium.copyWith(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Serious candidates invest in permanent marriage clarity.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Tier 1: Essential
              _buildTierCard(
                index: 0,
                title: 'ESSENTIAL REGISTRY',
                price: '\$29 / mo',
                description: 'Standard access to verified candidates and daily recommendations.',
                features: [
                  'Browse verified marriage profiles',
                  'Standard compatibility scoring',
                  'Basic AI Coach guidance',
                ],
              ),
              const SizedBox(height: 16),

              // Tier 2: Gold Sovereign (Popular)
              _buildTierCard(
                index: 1,
                title: 'GOLD SOVEREIGN',
                price: '\$69 / mo',
                description: 'Unlimited messaging and prioritized placement in verified candidate feeds.',
                features: [
                  'Unlimited direct conversations',
                  'Priority Didit Verification prominence',
                  'Full Psychological Radar breakdowns',
                  'See candidates who favorited your vows',
                ],
                isPopular: true,
              ),
              const SizedBox(height: 16),

              // Tier 3: Platinum Vows
              _buildTierCard(
                index: 2,
                title: 'PLATINUM VOWS',
                price: '\$149 / mo',
                description: 'Private concierge matchmaking with personalized marital guidance.',
                features: [
                  'All Gold Sovereign privileges',
                  'Direct 24/7 AI Behavioral Therapist',
                  'Ultra-priority high-trust placement',
                  'Comprehensive background certification',
                ],
              ),
              const SizedBox(height: 28),

              GoldButton(
                text: _selectedTier == 0
                    ? 'Select Essential'
                    : _selectedTier == 1
                        ? 'Upgrade to Gold Sovereign'
                        : 'Enter Platinum Vows',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Subscription successfully activated.')),
                  );
                  context.pop();
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Secured via RevenueCat / App Store In-App Purchases. Cancel anytime.',
                style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSubtle),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTierCard({
    required int index,
    required String title,
    required String price,
    required String description,
    required List<String> features,
    bool isPopular = false,
  }) {
    final isSelected = _selectedTier == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = index),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        border: Border.all(
          color: isSelected
              ? AppColors.champagneGold
              : isPopular
                  ? AppColors.champagneGold.withOpacity(0.5)
                  : AppColors.borderSubtle,
          width: isSelected ? 2.0 : 1.0,
        ),
        backgroundColor: isSelected
            ? AppColors.champagneGold.withOpacity(0.1)
            : AppColors.darkSlate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: AppTypography.labelLarge.copyWith(
                    color: isSelected ? AppColors.champagneGold : AppColors.textPure,
                  ),
                ),
                if (isPopular)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.roseGlow,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'MOST POPULAR',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 9,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              price,
              style: AppTypography.displayMedium.copyWith(
                fontSize: 24,
                color: AppColors.champagneGold,
              ),
            ),
            const SizedBox(height: 6),
            Text(description, style: AppTypography.bodySmall),
            const SizedBox(height: 14),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, size: 16, color: AppColors.champagneGold),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: AppTypography.bodySmall.copyWith(color: AppColors.textPure))),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
