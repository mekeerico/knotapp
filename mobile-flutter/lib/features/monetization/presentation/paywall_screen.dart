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

  static const _tierNames = ['Premium', 'Elite', 'Executive'];

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  void _toast(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: success ? AppColors.champagneGold : null,
        content: Text(
          message,
          style: success
              ? const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
              : null,
        ),
      ),
    );
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final user = ref.read(authProvider).user;
    if (user != null) {
      await RevenueCatService.ensureLoggedIn(user.id);
    }
    final offerings = await RevenueCatService.getOfferings();
    // Reconcile with the server so the "current plan" badge only reflects
    // a subscription the backend has verified with Google Play.
    try {
      await ref.read(authProvider.notifier).syncSubscription();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _isLoading = false;
      });
    }
  }

  /// Returns -1 for Free/Essential, 0 for Premium, 1 for Elite, 2 for Executive.
  /// Based solely on the server-verified profile.
  int _getCurrentTierRank(String? profileTier, bool isPremium) {
    if (!isPremium) return -1;
    final effectiveTier = (profileTier ?? '').trim().toLowerCase();
    if (effectiveTier.contains('executive')) return 2;
    if (effectiveTier.contains('elite')) return 1;
    if (effectiveTier.contains('premium')) return 0;
    return -1;
  }

  /// Strict package lookup. Never falls back to a different tier's product.
  Package? _getPackageForTier(int tier) {
    final packages = _offerings?.current?.availablePackages ?? [];
    final keyword = _tierNames[tier].toLowerCase();
    for (final p in packages) {
      final productId = p.storeProduct.identifier.toLowerCase();
      final packageId = p.identifier.toLowerCase();
      if (productId.contains(keyword) || packageId.contains(keyword)) return p;
    }
    return null;
  }

  Future<void> _handlePurchaseForTier(int tierIndex) async {
    setState(() => _selectedTier = tierIndex);

    final user = ref.read(authProvider).user;
    if (user == null) {
      _toast('Please sign in again to subscribe.');
      return;
    }

    final package = _getPackageForTier(tierIndex);
    if (package == null) {
      _toast(
        'This plan is not available from Google Play right now. Make sure you are signed into the Play Store and try again.',
      );
      _loadOfferings();
      return;
    }

    setState(() => _processingTier = tierIndex);

    try {
      // Purchase must be attached to THIS Knot account, never an anonymous/other one.
      final bound = await RevenueCatService.ensureLoggedIn(user.id);
      if (!bound) {
        _toast('Could not connect your account to Google Play billing. Please try again.');
        return;
      }

      // Opens the Google Play payment sheet. Throws if cancelled/failed.
      final result = await RevenueCatService.purchasePackage(package);

      // The transaction returned must be for the product the user actually chose.
      final expected = RevenueCatService.baseProductId(package.storeProduct.identifier);
      final purchased = RevenueCatService.baseProductId(result.storeTransaction.productIdentifier);
      if (purchased != expected) {
        _toast('Purchase could not be confirmed. If you were charged, tap Restore.');
        return;
      }

      // Only the backend (after verifying with RevenueCat/Google) can grant premium.
      final updated = await ref.read(authProvider.notifier).syncSubscription();
      final rank = _getCurrentTierRank(updated.subscriptionTier, updated.isPremium);
      if (rank >= tierIndex) {
        _toast(
          '🌟 ${updated.subscriptionTier} Registry Activated! Welcome to VIP Alignment.',
          success: true,
        );
      } else {
        _toast(
          'Payment received. Your plan will activate as soon as Google Play confirms it.',
        );
      }
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      switch (errorCode) {
        case PurchasesErrorCode.purchaseCancelledError:
          break; // user closed the payment sheet
        case PurchasesErrorCode.paymentPendingError:
          _toast(
            'Your payment is pending with Google Play. Your plan will activate once it is completed.',
          );
          break;
        case PurchasesErrorCode.productAlreadyPurchasedError:
        case PurchasesErrorCode.receiptAlreadyInUseError:
          _toast(
            'This Google Play account already has an active Knot subscription. Tap Restore if it belongs to this account.',
          );
          break;
        case PurchasesErrorCode.productNotAvailableForPurchaseError:
          _toast('This plan is not available for purchase in your region yet.');
          break;
        default:
          _toast(e.message ?? 'Purchase failed. Please try again.');
      }
    } catch (e) {
      _toast(
        'We could not verify your subscription right now. If you were charged, it will activate automatically shortly, or tap Restore.',
      );
    } finally {
      if (mounted) setState(() => _processingTier = null);
    }
  }

  Future<void> _handleRestore() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    setState(() => _isRestoring = true);
    try {
      final bound = await RevenueCatService.ensureLoggedIn(user.id);
      if (!bound) {
        _toast('Could not connect your account to Google Play billing. Please try again.');
        return;
      }
      await RevenueCatService.restorePurchases();
      final updated = await ref.read(authProvider.notifier).syncSubscription();
      if (updated.isPremium) {
        _toast('Purchases restored! Active Tier: ${updated.subscriptionTier}', success: true);
      } else {
        _toast('No active subscriptions found for this account.');
      }
    } on PlatformException catch (e) {
      _toast(e.message ?? 'Restore failed. Please try again.');
    } catch (e) {
      _toast('Could not verify your subscription right now. Please try again.');
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
