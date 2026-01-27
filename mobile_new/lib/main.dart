import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/supabase_service.dart';
import 'services/navigation_service.dart';
import 'parts/gig_alert_overlay.dart';
import 'parts/bottom_nav_shell.dart';
import 'services/gig_service.dart';
import 'managers/notifications_provider.dart';
import 'data_types/notification.dart';
import 'config/theme.dart';
import 'managers/auth_provider.dart';
import 'managers/theme_provider.dart';
import 'screens/login/login_screen.dart';
import 'screens/login/signup_screen.dart';
import 'screens/login/forgot_password_screen.dart';
import 'screens/swipe/swipe_feed_screen.dart';
import 'screens/milan/matches_list_screen.dart';
import 'screens/milan/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/edit_profile_screen.dart';
import 'screens/profile/settings_screen.dart';
import 'screens/kaam/post_task_screen.dart';
import 'screens/kaam/my_tasks_screen.dart';
import 'screens/kaam/posted_tasks_screen.dart';
import 'screens/kaam/task_feed_screen.dart';
import 'screens/kaam/task_details_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/login/verification_screen.dart';
import 'screens/task_completion_screen.dart';
import 'screens/kyc/kyc_verification_screen.dart';
import 'parts/animated_splash_screen.dart';
import 'screens/legal/about_us_screen.dart';
import 'screens/legal/contact_us_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_conditions_screen.dart';
import 'screens/legal/cancellation_refund_screen.dart';
import 'widgets/asap_notification_listener.dart';
import 'screens/milan/call_screen.dart';

void main() async {
  // ✨ Magic: Global error handling to catch terminal crashes
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    bool backendInitialized = false;
    String? initializationError;

    try {
      await SupabaseService.initialize();
      backendInitialized = true;
      print('✅ Supabase initialized successfully');
    } catch (e) {
      print('❌ Supabase initialization failed: $e');
      backendInitialized = false;
      initializationError = e.toString();
    }

    runApp(
      ProviderScope(
        child: MyApp(
          backendInitialized: backendInitialized,
          initializationError: initializationError,
        ),
      ),
    );
  }, (error, stack) {
    print('📦 FATAL GLOBAL ERROR: $error');
    print(stack);
  });
}

class MyApp extends ConsumerStatefulWidget {
  final bool backendInitialized;
  final String? initializationError;
  final bool forceContinue;

  const MyApp({
    Key? key,
    required this.backendInitialized,
    this.initializationError,
    this.forceContinue = false,
  }) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    // Safety check for initialized backend before metadata updates
    if (!widget.backendInitialized) return;
    
    final supabaseService = SupabaseService.instance;
    try {
      if (state == AppLifecycleState.resumed) {
        supabaseService.setUserOnline(true);
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
        supabaseService.setUserOnline(false);
      }
    } catch (e) {
      print('Presence update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'PartTimePaise',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: notificationMessengerKey,
      builder: (context, child) {
        // High-level safety fallback
        if (!widget.backendInitialized && !widget.forceContinue) {
          return _buildOfflineScreen();
        }

        return ASAPNotificationListener(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildOfflineScreen() {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('System Initialization Failure', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (widget.initializationError != null)
                Text(widget.initializationError!, style: const TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                   // Full restart logic
                   main();
                },
                child: const Text('RESTART APP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final GlobalKey<ScaffoldMessengerState> notificationMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
  final rootNavigatorKey = GlobalKey<NavigatorState>();

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

      final isLoginRoute = path == '/login' || path == '/signup' || path == '/forgot-password' || path == '/onboarding' || path == '/verification';

      if (!isAuthenticated && !isLoginRoute) return '/login';

      if (isAuthenticated && isLoginRoute) {
        if (authState.user == null) return null;
        if (authState.user!.verified) return '/swipe';
        return null; 
      }

      if (isAuthenticated && authState.user != null && !authState.user!.verified) {
        if (path != '/kyc-verification' && !isLoginRoute && path != '/privacy-policy' && path != '/terms-conditions' && path != '/contact-us') {
          return '/login';
        }
      }

      if (isAuthenticated && authState.user!.verified && path == '/kyc-verification') return '/swipe';

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const AnimatedSplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/signup', builder: (context, state) => const SignupScreen()),
      GoRoute(path: '/forgot-password', builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(path: '/verification', builder: (context, state) => const VerificationScreen()),
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: '/swipe', builder: (context, state) => const SwipeFeedScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/matches',
              builder: (context, state) => const MatchesListScreen(),
              routes: [GoRoute(path: ':matchId/chat', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => ChatScreen(matchId: state.pathParameters['matchId']!))],
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
      GoRoute(path: '/kyc-verification', builder: (context, state) => const KycVerificationScreen()),
      GoRoute(path: '/about-us', builder: (context, state) => const AboutUsScreen()),
      GoRoute(path: '/contact-us', builder: (context, state) => const ContactUsScreen()),
      GoRoute(path: '/privacy-policy', builder: (context, state) => const PrivacyPolicyScreen()),
      GoRoute(path: '/terms-conditions', builder: (context, state) => const TermsConditionsScreen()),
      GoRoute(path: '/cancellation-refund', builder: (context, state) => const CancellationRefundScreen()),
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
