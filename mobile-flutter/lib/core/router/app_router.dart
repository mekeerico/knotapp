import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_screen.dart';
import '../../features/auth/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/discovery/models/match_profile.dart';
import '../../features/discovery/presentation/discovery_screen.dart';
import '../../features/discovery/presentation/profile_detail_screen.dart';
import '../../features/ai_coach/presentation/ai_coach_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/chat/presentation/messages_list_screen.dart';
import '../../features/insights/presentation/insights_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/edit_profile_screen.dart';
import '../../features/profile/presentation/manage_photos_screen.dart';
import '../../features/monetization/presentation/paywall_screen.dart';
import '../../features/verification/presentation/didit_verification_screen.dart';
import '../../features/home/presentation/main_navigation_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorDiscovery = GlobalKey<NavigatorState>();
final _shellNavigatorInsights = GlobalKey<NavigatorState>();
final _shellNavigatorCoach = GlobalKey<NavigatorState>();
final _shellNavigatorMessages = GlobalKey<NavigatorState>();
final _shellNavigatorProfile = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final isAuth = authState.isAuthenticated;
    final isAuthRoute = state.matchedLocation == '/auth';
    final isWelcomeRoute = state.matchedLocation == '/welcome';
    final isPreviewWelcome = state.uri.queryParameters['preview'] == 'true';
    final isOnboardingRoute = state.matchedLocation == '/onboarding';
    final isVerificationRoute = state.matchedLocation == '/verification';

    if (!isAuth) {
      if (isWelcomeRoute) {
        // Returning users who already completed welcome go directly to /auth unless explicitly previewing
        if (authState.hasSeenWelcome && !isPreviewWelcome) {
          return '/auth';
        }
        return null;
      }
      if (isAuthRoute) {
        return null;
      }
      return authState.hasSeenWelcome ? '/auth' : '/welcome';
    }

    if (isAuth && authState.needsOnboarding && !isOnboardingRoute && !isVerificationRoute) {
      return '/onboarding';
    }

    if (isAuth && (isAuthRoute || isWelcomeRoute)) {
      return authState.needsOnboarding ? '/onboarding' : '/discovery';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/discovery',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth',
        builder: (context, state) {
          final isRegister = state.uri.queryParameters['mode'] == 'register';
          return AuthScreen(initialSignUp: isRegister);
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) => const DiditVerificationScreen(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/manage-photos',
        builder: (context, state) => const ManagePhotosScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/profile-detail',
        builder: (context, state) {
          final profile = state.extra as MatchProfile;
          return ProfileDetailScreen(profile: profile);
        },
      ),
      GoRoute(
        path: '/chat/:id',
        builder: (context, state) {
          final matchId = state.pathParameters['id'] ?? '';
          final matchProfile = state.extra as MatchProfile?;
          return ChatScreen(matchId: matchId, matchProfile: matchProfile);
        },
      ),

      // 5-Tab Shell Route
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationShell(navigationShell: navigationShell);
        },
        branches: [
          // Branch 1: Discovery / Matches
          StatefulShellBranch(
            navigatorKey: _shellNavigatorDiscovery,
            routes: [
              GoRoute(
                path: '/discovery',
                builder: (context, state) => const DiscoveryScreen(),
              ),
            ],
          ),

          // Branch 2: Insights
          StatefulShellBranch(
            navigatorKey: _shellNavigatorInsights,
            routes: [
              GoRoute(
                path: '/insights',
                builder: (context, state) => const InsightsScreen(),
              ),
            ],
          ),

          // Branch 3: AI Coach
          StatefulShellBranch(
            navigatorKey: _shellNavigatorCoach,
            routes: [
              GoRoute(
                path: '/ai-coach',
                builder: (context, state) => const AICoachScreen(),
              ),
            ],
          ),

          // Branch 4: Messages
          StatefulShellBranch(
            navigatorKey: _shellNavigatorMessages,
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) => const MessagesListScreen(),
              ),
            ],
          ),

          // Branch 5: Profile
          StatefulShellBranch(
            navigatorKey: _shellNavigatorProfile,
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
