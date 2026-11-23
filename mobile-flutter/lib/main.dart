import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/data/location_data.dart';
import 'core/router/app_router.dart';
import 'core/services/revenue_cat_service.dart';
import 'core/storage/secure_storage_service.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Premium immersive UI styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.obsidianBlack,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Preferred device orientations for optimal camera scanning & card swipe physics
  try {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  } catch (_) {}

  // Safe pre-flight check of local secure storage (never block or crash runApp)
  bool hasSeenWelcome = false;
  bool hasToken = false;
  try {
    final storage = SecureStorageService();
    hasSeenWelcome = await storage.hasSeenWelcome().timeout(
      const Duration(seconds: 3),
      onTimeout: () => false,
    );
    final token = await storage.getToken().timeout(
      const Duration(seconds: 3),
      onTimeout: () => null,
    );
    hasToken = token != null && token.isNotEmpty;
  } catch (_) {
    hasSeenWelcome = false;
    hasToken = false;
  }

  // Load full world country -> state/province/region dataset safely
  try {
    await KnotLocationData.load().timeout(
      const Duration(seconds: 3),
      onTimeout: () {},
    );
  } catch (_) {}

  // Initialize RevenueCat in background so billing SDK never delays first frame
  RevenueCatService.init();

  runApp(
    ProviderScope(
      overrides: [
        initialAuthStateProvider.overrideWithValue(
          InitialAuthState(
            hasSeenWelcome: hasSeenWelcome,
            hasToken: hasToken,
          ),
        ),
      ],
      child: const KnotApp(),
    ),
  );
}

class KnotApp extends ConsumerWidget {
  const KnotApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'KNOT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
