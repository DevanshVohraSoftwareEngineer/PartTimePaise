import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
import '../parts/animated_splash_screen.dart';
import '../screens/worker/asap_mode_screen.dart';
import '../screens/legal/about_us_screen.dart';
import '../screens/legal/contact_us_screen.dart';
import '../screens/legal/privacy_policy_screen.dart';
import '../screens/legal/terms_conditions_screen.dart';
import '../screens/legal/cancellation_refund_screen.dart';
import '../screens/task_completion_screen.dart';
import '../screens/milan/call_screen.dart';
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
    initialLocation: '/splash',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState.sessionUser != null;
      final path = state.matchedLocation;
      
      if (path == '/splash') return null;
      if (authState.isLoading && authState.user == null) return null;

      // ... rest of logic ...
      
      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }
      
      if (isAuthenticated && isLoginRoute) {
        return '/swipe';
      }
      
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const AnimatedSplashScreen()),
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

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/swipe', builder: (context, state) => const SwipeFeedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/categories', builder: (context, state) => const CategoriesScreen())]),
          StatefulShellBranch(routes: [
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
          ]),
          StatefulShellBranch(routes: [GoRoute(path: '/post-task', builder: (context, state) => const PostTaskScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: '/posted-tasks', builder: (context, state) => const PostedTasksScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/my-tasks',
              builder: (context, state) => const MyTasksScreen(),
              routes: [GoRoute(path: 'completion/:taskId', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => TaskCompletionScreen(taskId: state.pathParameters['taskId']!))],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
              routes: [
                GoRoute(path: 'edit', builder: (context, state) => const EditProfileScreen()),
                GoRoute(path: 'settings', builder: (context, state) => const SettingsScreen()),
              ],
            ),
          ]),
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
    ],
    errorBuilder: (context, state) => Scaffold(body: Center(child: Text('Error: ${state.error}'))),
  );
});
