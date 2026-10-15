import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../../../core/widgets/knot_app_bar.dart';
import '../../auth/providers/auth_provider.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedTier = 1; // 0: Premium, 1: Elite, 2: Executive
  bool _isLoading = true;
  bool _isProcessing = false;
  Offerings? _offerings;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final offerings = await RevenueCatService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  Package? _getPackageForTier(int tier) {
    final packages = _offerings?.current?.availablePackages ?? [];
    if (packages.isEmpty) return null;

    if (tier == 0) {
      return packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains('premium') || p.storeProduct.identifier.contains('premium'),
        orElse: () => packages[0],
      );
    } else if (tier == 1) {
      return packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains('elite') || p.storeProduct.identifier.contains('elite'),
        orElse: () => packages.length > 1 ? packages[1] : packages[0],
      );
    } else {
      return packages.firstWhere(
        (p) => p.identifier.toLowerCase().contains('executive') || p.storeProduct.identifier.contains('executive'),
        orElse: () => packages.length > 2 ? packages[2] : packages.last,
      );
    }
  }

  Future<void> _handlePurchase() async {
    final package = _getPackageForTier(_selectedTier);
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connecting to Google Play Store... Please ensure you are logged into Google Play.'),
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final customerInfo = await RevenueCatService.purchasePackage(package);
      if (customerInfo != null && RevenueCatService.hasActiveSubscription(customerInfo)) {
        final tierName = _selectedTier == 0
            ? 'Premium'
            : _selectedTier == 1
                ? 'Elite'
                : 'Executive';

        // Update local auth state & sync with backend
        ref.read(authProvider.notifier).updateProfile({
          'isPremium': true,
          'subscriptionTier': tierName,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.champagneGold,
              content: Text(
                '🌟 $tierName Registry Activated! Welcome to VIP Alignment.',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
          context.pop();
        }
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message ?? 'Purchase failed. Please try again.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing purchase: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isProcessing = true);
    try {
      final customerInfo = await RevenueCatService.restorePurchases();
      if (customerInfo != null && RevenueCatService.hasActiveSubscription(customerInfo)) {
        final activeTier = RevenueCatService.getActiveTier(customerInfo) ?? 'Premium';
        ref.read(authProvider.notifier).updateProfile({
          'isPremium': true,
          'subscriptionTier': activeTier,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.champagneGold,
              content: Text(
                'Purchases restored! Active Tier: $activeTier',
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No active subscriptions found for this account.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pkg0 = _getPackageForTier(0);
    final pkg1 = _getPackageForTier(1);
    final pkg2 = _getPackageForTier(2);

    final price0 = pkg0?.storeProduct.priceString ?? '\$29 / mo';
    final price1 = pkg1?.storeProduct.priceString ?? '\$69 / mo';
    final price2 = pkg2?.storeProduct.priceString ?? '\$149 / mo';

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'SOVEREIGN VIP TIERS',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.champagneGold),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _isProcessing ? null : _handleRestore,
            child: Text(
              'Restore',
              style: AppTypography.labelLarge.copyWith(
                fontSize: 12,
                color: AppColors.champagneGold,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.champagneGold),
              )
            : SingleChildScrollView(
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

              // Tier 1: Premium
              _buildTierCard(
                index: 0,
                title: 'PREMIUM REGISTRY',
                price: price0,
                description: 'Standard access to verified candidates and daily recommendations.',
                features: const [
                  'Browse verified marriage profiles',
                  'Standard compatibility scoring',
                  'Basic AI Coach guidance',
                ],
              ),
              const SizedBox(height: 16),

              // Tier 2: Elite (Most Popular)
              _buildTierCard(
                index: 1,
                title: 'ELITE SOVEREIGN',
                price: price1,
                description: 'Unlimited messaging and prioritized placement in verified candidate feeds.',
                features: const [
                  'Unlimited direct conversations',
                  'Priority Didit Verification prominence',
                  'Full Psychological Radar breakdowns',
                  'See candidates who favorited your vows',
                ],
                isPopular: true,
              ),
              const SizedBox(height: 16),

              // Tier 3: Executive
              _buildTierCard(
                index: 2,
                title: 'EXECUTIVE VOWS',
                price: price2,
                description: 'Private concierge matchmaking with personalized marital guidance.',
                features: const [
                  'All Elite Sovereign privileges',
                  'Direct 24/7 AI Behavioral Therapist',
                  'Ultra-priority high-trust placement',
                  'Comprehensive background certification',
                ],
              ),
              const SizedBox(height: 28),

              if (_isProcessing)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: CircularProgressIndicator(color: AppColors.champagneGold),
                )
              else
                GoldButton(
                  text: _selectedTier == 0
                      ? 'Upgrade to Premium'
                      : _selectedTier == 1
                          ? 'Upgrade to Elite Sovereign'
                          : 'Enter Executive Vows',
                  onPressed: _handlePurchase,
                ),
              const SizedBox(height: 14),
              Text(
                'Secured via Google Play / App Store In-App Purchases. Cancel anytime.',
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
                  ? AppColors.champagneGold.withValues(alpha: 0.5)
                  : AppColors.borderSubtle,
          width: isSelected ? 2.0 : 1.0,
        ),
        backgroundColor: isSelected
            ? AppColors.champagneGold.withValues(alpha: 0.1)
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
