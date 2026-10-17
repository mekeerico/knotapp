import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/revenue_cat_service.dart';
import '../../../core/services/currency_service.dart';
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
  int? _processingTier;
  bool _isLoading = true;
  bool _isRestoring = false;
  Offerings? _offerings;
  String? _activeStoreTier;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final offerings = await RevenueCatService.getOfferings();
    final customerInfo = await RevenueCatService.getCustomerInfo();
    String? detectedTier;
    if (customerInfo != null && RevenueCatService.hasActiveSubscription(customerInfo)) {
      detectedTier = RevenueCatService.getActiveTier(customerInfo);
    }
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _activeStoreTier = detectedTier;
        _isLoading = false;
      });
    }
  }

  /// Returns -1 for Free/Essential, 0 for Premium, 1 for Elite, 2 for Executive
  int _getCurrentTierRank(String? profileTier, bool isPremium) {
    final effectiveTier = (_activeStoreTier ?? profileTier ?? '').trim().toLowerCase();
    if (effectiveTier.contains('executive')) return 2;
    if (effectiveTier.contains('elite')) return 1;
    if (effectiveTier.contains('premium') || isPremium) return 0;
    return -1;
  }

  Package? _getPackageForTier(int tier) {
    final packages = _offerings?.current?.availablePackages ?? [];
    if (packages.isEmpty) return null;

    if (tier == 0) {
      return packages.firstWhere(
        (p) =>
            p.storeProduct.identifier.toLowerCase().contains('knot_premium') ||
            p.identifier.toLowerCase().contains('premium'),
        orElse: () => packages[0],
      );
    } else if (tier == 1) {
      return packages.firstWhere(
        (p) =>
            p.storeProduct.identifier.toLowerCase().contains('knot__elite') ||
            p.storeProduct.identifier.toLowerCase().contains('elite') ||
            p.identifier.toLowerCase().contains('elite'),
        orElse: () => packages.length > 1 ? packages[1] : packages[0],
      );
    } else {
      return packages.firstWhere(
        (p) =>
            p.storeProduct.identifier.toLowerCase().contains('knot_executive') ||
            p.identifier.toLowerCase().contains('executive'),
        orElse: () => packages.length > 2 ? packages[2] : packages.last,
      );
    }
  }

  Future<void> _handlePurchaseForTier(int tierIndex) async {
    setState(() => _selectedTier = tierIndex);

    final package = _getPackageForTier(tierIndex);
    if (package == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Connecting to Google Play Store... Please ensure you are signed into Google Play.',
          ),
        ),
      );
      return;
    }

    setState(() => _processingTier = tierIndex);

    try {
      final customerInfo = await RevenueCatService.purchasePackage(package);
      if (customerInfo != null && RevenueCatService.hasActiveSubscription(customerInfo)) {
        final tierName = tierIndex == 0
            ? 'Premium'
            : tierIndex == 1
                ? 'Elite'
                : 'Executive';

        setState(() => _activeStoreTier = tierName);

        // Update local auth state & sync with backend
        await ref.read(authProvider.notifier).updateProfile({
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
      if (mounted) setState(() => _processingTier = null);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isRestoring = true);
    try {
      final customerInfo = await RevenueCatService.restorePurchases();
      if (customerInfo != null && RevenueCatService.hasActiveSubscription(customerInfo)) {
        final activeTier = RevenueCatService.getActiveTier(customerInfo) ?? 'Premium';
        setState(() => _activeStoreTier = activeTier);
        await ref.read(authProvider.notifier).updateProfile({
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
      if (mounted) setState(() => _isRestoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final userCountry = user?.residenceCountry;
    final currentTierRank = _getCurrentTierRank(
      user?.subscriptionTier,
      user?.isPremium ?? false,
    );

    final pkg0 = _getPackageForTier(0);
    final pkg1 = _getPackageForTier(1);
    final pkg2 = _getPackageForTier(2);

    final price0 = pkg0?.storeProduct.priceString ??
        CurrencyService.formatTierPrice('Premium', userCountry);
    final price1 = pkg1?.storeProduct.priceString ??
        CurrencyService.formatTierPrice('Elite', userCountry);
    final price2 = pkg2?.storeProduct.priceString ??
        CurrencyService.formatTierPrice('Executive', userCountry);

    final sub0 = CurrencyService.getSettlementSubtitle('Premium', userCountry);
    final sub1 = CurrencyService.getSettlementSubtitle('Elite', userCountry);
    final sub2 = CurrencyService.getSettlementSubtitle('Executive', userCountry);

    final isAnyBusy = _processingTier != null || _isRestoring;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      appBar: KnotAppBar(
        title: 'SOVEREIGN TIERS',
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.champagneGold),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: isAnyBusy ? null : _handleRestore,
            child: _isRestoring
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.champagneGold,
                    ),
                  )
                : Text(
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

                    // Tier 1: Premium Registry
                    _buildTierCard(
                      index: 0,
                      title: 'PREMIUM REGISTRY',
                      buttonText: 'Upgrade to Premium',
                      price: price0,
                      settlementSubtitle: sub0,
                      description:
                          'Standard access to verified candidates and daily recommendations.',
                      features: const [
                        '15 AI-Curated verified matches per day',
                        'Unlimited intentional messaging',
                        '24/7 AI Relationship Coach guidance',
                        'Detailed compatibility breakdowns',
                      ],
                      currentTierRank: currentTierRank,
                    ),
                    const SizedBox(height: 18),

                    // Tier 2: Elite Sovereign (Most Popular)
                    _buildTierCard(
                      index: 1,
                      title: 'ELITE SOVEREIGN',
                      buttonText: 'Upgrade to Elite Sovereign',
                      price: price1,
                      settlementSubtitle: sub1,
                      description:
                          'Unlimited messaging and prioritized placement in verified candidate feeds.',
                      features: const [
                        '25 Elite matches per day & unlimited chats',
                        'Priority Didit Verification prominence',
                        'Full Psychological Radar breakdowns',
                        'See candidates who favorited your vows',
                      ],
                      isPopular: true,
                      currentTierRank: currentTierRank,
                    ),
                    const SizedBox(height: 18),

                    // Tier 3: Executive Vows
                    _buildTierCard(
                      index: 2,
                      title: 'EXECUTIVE VOWS',
                      buttonText: 'Upgrade to Executive Vows',
                      price: price2,
                      settlementSubtitle: sub2,
                      description:
                          'Private concierge matchmaking with personalized marital guidance.',
                      features: const [
                        'All Elite Sovereign privileges',
                        'Direct 24/7 AI Behavioral Therapist',
                        'Ultra-priority high-trust placement',
                        'Comprehensive background certification',
                      ],
                      currentTierRank: currentTierRank,
                    ),
                    const SizedBox(height: 20),

                    Text(
                      'Displayed in your local currency. All subscriptions are billed securely via Google Play in USD (\$). Cancel anytime.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.textSubtle,
                      ),
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
    required String buttonText,
    required String price,
    String? settlementSubtitle,
    required String description,
    required List<String> features,
    required int currentTierRank,
    bool isPopular = false,
  }) {
    final isSelected = _selectedTier == index;
    final isCurrentPlan = currentTierRank == index;
    final isLowerThanCurrent = currentTierRank > index;
    final isThisProcessing = _processingTier == index;
    final isOtherProcessing = _processingTier != null && _processingTier != index;

    return GestureDetector(
      onTap: () => setState(() => _selectedTier = index),
      child: GlassCard(
        padding: const EdgeInsets.all(20),
        border: Border.all(
          color: isCurrentPlan
              ? AppColors.emeraldVerified
              : isSelected
                  ? AppColors.champagneGold
                  : isPopular
                      ? AppColors.champagneGold.withValues(alpha: 0.5)
                      : AppColors.borderSubtle,
          width: (isCurrentPlan || isSelected) ? 2.0 : 1.0,
        ),
        backgroundColor: isCurrentPlan
            ? AppColors.emeraldVerified.withValues(alpha: 0.08)
            : isSelected
                ? AppColors.champagneGold.withValues(alpha: 0.1)
                : AppColors.darkSlate,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: AppTypography.labelLarge.copyWith(
                      color: isCurrentPlan
                          ? AppColors.emeraldVerified
                          : isSelected
                              ? AppColors.champagneGold
                              : AppColors.textPure,
                    ),
                  ),
                ),
                if (isCurrentPlan)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldVerified.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.emeraldVerified),
                    ),
                    child: Text(
                      'CURRENT PLAN',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 9,
                        color: AppColors.emeraldVerified,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  )
                else if (isPopular)
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
            if (settlementSubtitle != null) ...[
              const SizedBox(height: 2),
              Text(
                settlementSubtitle,
                style: AppTypography.bodySmall.copyWith(
                  fontSize: 10.5,
                  color: AppColors.champagneGold.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(description, style: AppTypography.bodySmall),
            const SizedBox(height: 14),
            ...features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: AppColors.champagneGold,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPure,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dedicated Per-Tier Action Button
            if (isCurrentPlan)
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.emeraldVerified.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.emeraldVerified.withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified,
                      size: 18,
                      color: AppColors.emeraldVerified,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Subscribed • Current Tier',
                      style: AppTypography.button.copyWith(
                        color: AppColors.emeraldVerified,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              )
            else if (isLowerThanCurrent)
              Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      size: 16,
                      color: AppColors.textSubtle,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Included in Your Higher Tier',
                      style: AppTypography.button.copyWith(
                        color: AppColors.textSubtle,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              GoldButton(
                text: buttonText,
                height: 48,
                isLoading: isThisProcessing,
                isSecondary: !isSelected && !isPopular,
                onPressed: isOtherProcessing
                    ? null
                    : () => _handlePurchaseForTier(index),
              ),
          ],
        ),
      ),
    );
  }
}
