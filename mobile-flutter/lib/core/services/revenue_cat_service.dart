import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class RevenueCatService {
  // Live Google Play Store API Key configured in RevenueCat
  static const String googleApiKey = 'goog_dgDfCMLbhuAGIqZjWSRDAdSScHt';
  static const String appleApiKey = 'appl_placeholder';

  // Entitlement Identifiers matching RevenueCat Dashboard
  static const String entitlementPremium = 'Premium';
  static const String entitlementElite = 'Elite';
  static const String entitlementExecutive = 'Executive';

  static bool _initialized = false;

  /// Initializes RevenueCat with the configured Google Play / Apple API Keys
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      PurchasesConfiguration? configuration;
      if (Platform.isAndroid) {
        configuration = PurchasesConfiguration(googleApiKey);
      } else if (Platform.isIOS) {
        configuration = PurchasesConfiguration(appleApiKey);
      }

      if (configuration != null) {
        await Purchases.configure(configuration);
        _initialized = true;
        debugPrint('[RevenueCat] Successfully configured for ${Platform.operatingSystem}');
      }
    } catch (e) {
      debugPrint('[RevenueCat] Configuration initialization error: $e');
    }
  }

  /// Binds the RevenueCat customer session to the specific authenticated member UUID
  static Future<void> logIn(String userId) async {
    if (!_initialized) await init();
    try {
      await Purchases.logIn(userId);
      debugPrint('[RevenueCat] Logged in as user: $userId');
    } catch (e) {
      debugPrint('[RevenueCat] Error logging in user $userId: $e');
    }
  }

  /// Clears RevenueCat session on user logout
  static Future<void> logOut() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
      debugPrint('[RevenueCat] Logged out user');
    } catch (e) {
      debugPrint('[RevenueCat] Error logging out: $e');
    }
  }

  /// Fetches published offerings and packages from RevenueCat
  static Future<Offerings?> getOfferings() async {
    if (!_initialized) await init();
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] Error fetching offerings: $e');
      return null;
    }
  }

  /// Fetches current customer info and active entitlements from RevenueCat
  static Future<CustomerInfo?> getCustomerInfo() async {
    if (!_initialized) await init();
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[RevenueCat] Error fetching customer info: $e');
      return null;
    }
  }

  /// Initiates native In-App Purchase for the chosen package
  static Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_initialized) await init();
    try {
      final customerInfo = await Purchases.purchasePackage(package);
      return customerInfo;
    } catch (e) {
      debugPrint('[RevenueCat] Purchase failed or cancelled: $e');
      rethrow;
    }
  }

  /// Restores existing subscription across user devices / reinstalls
  static Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) await init();
    try {
      final customerInfo = await Purchases.restorePurchases();
      return customerInfo;
    } catch (e) {
      debugPrint('[RevenueCat] Restore failed: $e');
      rethrow;
    }
  }

  /// Verifies if any of the VIP entitlements are currently active
  static bool hasActiveSubscription(CustomerInfo info) {
    return info.entitlements.all[entitlementPremium]?.isActive == true ||
        info.entitlements.all[entitlementElite]?.isActive == true ||
        info.entitlements.all[entitlementExecutive]?.isActive == true;
  }

  /// Returns the highest active tier identifier, or null if unentitled
  static String? getActiveTier(CustomerInfo info) {
    if (info.entitlements.all[entitlementExecutive]?.isActive == true) return 'Executive';
    if (info.entitlements.all[entitlementElite]?.isActive == true) return 'Elite';
    if (info.entitlements.all[entitlementPremium]?.isActive == true) return 'Premium';
    return null;
  }
}
