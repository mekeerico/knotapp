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
  static Future<void>? _initFuture;

  /// Initializes RevenueCat with the configured Google Play / Apple API Keys
  static Future<void> init() {
    if (_initialized) return Future.value();
    return _initFuture ??= _doInit();
  }

  static Future<void> _doInit() async {
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
    } finally {
      if (!_initialized) _initFuture = null; // allow a retry later
    }
  }

  /// Binds the RevenueCat customer session to the specific authenticated member UUID
  static Future<void> logIn(String userId) async {
    if (!_initialized) await init();
    if (!_initialized) return;
    try {
      await Purchases.logIn(userId);
      debugPrint('[RevenueCat] Logged in as user: $userId');
    } catch (e) {
      debugPrint('[RevenueCat] Error logging in user $userId: $e');
    }
  }

  /// Guarantees the billing session belongs to [userId] before any purchase/restore.
  /// Returns false if the session could not be bound (purchase must NOT proceed,
  /// otherwise it would be attached to an anonymous or a different Knot account).
  static Future<bool> ensureLoggedIn(String userId) async {
    if (!_initialized) await init();
    if (!_initialized) return false;
    try {
      if (await Purchases.appUserID != userId) {
        await Purchases.logIn(userId);
      }
      return await Purchases.appUserID == userId;
    } catch (e) {
      debugPrint('[RevenueCat] ensureLoggedIn failed for $userId: $e');
      return false;
    }
  }

  /// Clears RevenueCat session on user logout
  static Future<void> logOut() async {
    if (!_initialized) return;
    try {
      if (await Purchases.isAnonymous) return;
      await Purchases.logOut();
      debugPrint('[RevenueCat] Logged out user');
    } catch (e) {
      debugPrint('[RevenueCat] Error logging out: $e');
    }
  }

  /// Fetches published offerings and packages from RevenueCat
  static Future<Offerings?> getOfferings() async {
    if (!_initialized) await init();
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RevenueCat] Error fetching offerings: $e');
      return null;
    }
  }

  /// Initiates the native Google Play / App Store purchase sheet for [package].
  /// Throws a [PlatformException] when cancelled or failed.
  static Future<PurchaseResult> purchasePackage(Package package) async {
    if (!_initialized) await init();
    if (!_initialized) {
      throw Exception('Store billing is not available on this device.');
    }
    return Purchases.purchasePackage(package);
  }

  /// Restores existing subscription across user devices / reinstalls
  static Future<CustomerInfo?> restorePurchases() async {
    if (!_initialized) await init();
    if (!_initialized) return null;
    return Purchases.restorePurchases();
  }

  /// Google Play product ids come as "productId:basePlanId"; compare on productId.
  static String baseProductId(String id) => id.split(':').first.trim().toLowerCase();

  /// Returns the tier only if an ACTIVE entitlement is backed by exactly [productId].
  static String? activeTierForProduct(CustomerInfo info, String productId) {
    final target = baseProductId(productId);
    for (final ent in info.entitlements.active.values) {
      if (baseProductId(ent.productIdentifier) != target) continue;
      final id = ent.identifier.toLowerCase();
      if (id.contains('executive')) return 'Executive';
      if (id.contains('elite')) return 'Elite';
      if (id.contains('premium')) return 'Premium';
    }
    return null;
  }
}
