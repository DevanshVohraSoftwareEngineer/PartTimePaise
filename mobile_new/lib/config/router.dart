import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../managers/auth_provider.dart';
import '../screens/login/login_screen.dart';
import '../screens/login/signup_screen.dart';
import '../screens/login/forgot_password_screen.dart';
import '../screens/login/reset_password_screen.dart';
import '../screens/login/auth_success_screen.dart';
import '../screens/swipe/swipe_feed_screen.dart';
import '../screens/milan/matches_list_screen.dart';
import '../screens/milan/chat_screen.dart';
import '../screens/categories_screen.dart';
import '../screens/calorie_counter_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/settings_screen.dart';
import '../screens/kaam/post_task_screen.dart';
import '../screens/kaam/my_tasks_screen.dart';
import '../screens/kaam/posted_tasks_screen.dart';
import '../screens/kaam/task_feed_screen.dart';
import '../screens/kaam/task_details_screen.dart';
import '../screens/kyc/kyc_verification_screen.dart';

import '../screens/worker/asap_mode_screen.dart';
import '../screens/legal/about_us_screen.dart';
import '../screens/legal/contact_us_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_conditions_screen.dart';
import '../screens/legal/cancellation_refund_screen.dart';
import '../screens/task_completion_screen.dart';
import '../screens/milan/call_screen.dart';
import '../screens/kaam/task_navigation_screen.dart';
import '../parts/bottom_nav_shell.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/swipe',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.sessionUser != null;
      final path = state.matchedLocation;

      // ✨ Magic: Debugging KYC invisibility
      print('🛡️ [Router] isAuthenticated=$isAuthenticated, path=$path, isLoading=${authState.isLoading}, userLoaded=${authState.user != null}');

      if (isAuthenticated) {
        final user = authState.user;
        final isVerified = user?.verified ?? false;
        final isRestricted = authState.isRestricted;

        // 🛡️ Loading Guard (Inside Auth): If user object is null but session is active, stay put.
        // This prevents kicking verified users to KYC screen during the split-second profile fetch.
        if (user == null && authState.isLoading) {
           print('🛡️ [Router] Authenticated but profile loading. Waiting...');
           return null;
        }

        // 1. Mandatory KYC Guard (Forward only)
        if (path != '/kyc-verification' && path != '/login' && path != '/profile/settings' && path != '/check-in') {
          if (!isVerified) {
            print('🛡️ [Router] User NOT verified. Redirecting to KYC.');
            return '/kyc-verification';
          }
          
          if (isRestricted) {
             print('🛡️ [Router] Restricted user but verified. Allowing access, but might block specific actions later.');
          }
        }

        // 2. Verified Exit Guard (If verified and on KYC route, push to feed)
        if (isVerified && !isRestricted && (path == '/kyc-verification' || path == '/check-in')) {
          print('🛡️ [Router] Verified user on KYC route, pushing to Swipe Feed');
          return '/swipe';
        }
      }

      // 2. GLOBAL LOADING GUARD (Only for initial boot/unauthenticated)
      if (authState.isLoading && authState.user == null) {
        print('🛡️ [Router] Auth state is loading and no user yet, staying put.');
        return null;
      }

      // 3. AUTH REDIRECTION
      final isLoginRoute = path == '/login' || path == '/signup' || path == '/forgot-password' || path == '/verification' || path == '/reset-password';
      
      if (!isAuthenticated && !isLoginRoute) {
        print('🛡️ [Router] Not authenticated, redirecting to /login');
        return '/login';
      }
      
      if (isAuthenticated && isLoginRoute) {
        print('🛡️ [Router] Authenticated on login route, redirecting to home');
        return '/swipe';
      }
      
      // Handle Password Recovery Redirection
      if (authState.isPasswordRecovery && path != '/reset-password') {
        return '/reset-password';
      }
      
      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => '/swipe'),
      // Native splash handles initial loading, redirecting to /swipe or /login
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/reset-password', builder: (context, state) => const ResetPasswordScreen()),
      GoRoute(
        path: '/auth-success', 
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AuthSuccessScreen(
            title: extra?['title'] ?? 'Successful!',
            message: extra?['message'] ?? 'Action completed successfully.',
            buttonText: extra?['buttonText'] ?? 'GO TO LOGIN',
            targetRoute: extra?['targetRoute'] ?? '/login',
          );
        },
      ),
      GoRoute(path: '/asap-mode', builder: (context, state) => const ASAPModeScreen()),
      GoRoute(path: '/calorie-counter', builder: (context, state) => const CalorieCounterScreen()),
      GoRoute(
        path: '/edit-task/:taskId',
        builder: (context, state) => PostTaskScreen(taskIdToEdit: state.pathParameters['taskId']),
      ),
      GoRoute(
        path: '/task-navigation',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return TaskNavigationScreen(
            taskLocation: extras['location'] as LatLng,
            taskTitle: extras['title'] as String,
          );
        },
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/swipe', builder: (context, state) => const SwipeFeedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen())]),
          // Matches (Chat) moved to top-level
          
          StatefulShellBranch(routes: [GoRoute(path: '/post-task', builder: (context, state) => const PostTaskScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/posted-tasks', builder: (context, state) => const PostedTasksScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/my-tasks',
              builder: (context, state) => const MyTasksScreen(),
              routes: [GoRoute(path: 'completion/:taskId', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => TaskCompletionScreen(taskId: state.pathParameters['taskId']!))],
            ),
          ]),
          // Profile moved to top-level
        ],
      ),
      GoRoute(path: '/task-feed', builder: (context, state) => const TaskFeedScreen()),
      GoRoute(
        path: '/task-details/:taskId',
        builder: (context, state) => TaskDetailsScreen(taskId: state.pathParameters['taskId']!),
      ),
      GoRoute(path: '/about-us', builder: (context, state) => const AboutUsScreen()),
      GoRoute(path: '/contact-us', builder: (context, state) => const ContactUsScreen()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms-conditions', builder: (context, state) => const TermsConditionsScreen()),
      GoRoute(path: '/cancellation-refund', builder: (context, state) => const CancellationRefundScreen()),
      GoRoute(
        path: '/chat/:matchId',
        parentNavigatorKey: rootNavigatorKey,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          final autofocus = state.uri.queryParameters['autofocus'] == 'true';
          return ChatScreen(matchId: matchId, autofocus: autofocus);
        },
      ),
      GoRoute(
        path: '/call/:matchId',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>?;
          return CallScreen(
            matchId: state.pathParameters['matchId']!,
            isVoiceOnly: extras?['isVoiceOnly'] ?? false,
            otherUserName: extras?['otherUserName'] ?? 'Worker',
          );
        },
      ),
      GoRoute(path: '/check-in', builder: (context, state) => const KYCVerificationScreen()), // Alias or temp
      GoRoute(path: '/kyc-verification', builder: (context, state) => const KYCVerificationScreen()),
      
      // ✨ TOP-LEVEL ROUTES (Full Screen)
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchesListScreen(),
        routes: [
          GoRoute(
            path: ':matchId/chat', 
            parentNavigatorKey: rootNavigatorKey, 
            builder: (context, state) {
              final matchId = state.pathParameters['matchId']!;
              final autofocus = state.uri.queryParameters['autofocus'] == 'true';
              return ChatScreen(matchId: matchId, autofocus: autofocus);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
          GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
