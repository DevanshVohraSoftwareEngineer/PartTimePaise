import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'services/supabase_service.dart';
import 'config/theme.dart';
import 'managers/auth_provider.dart';
import 'managers/theme_provider.dart';
import 'widgets/asap_notification_listener.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'config/router.dart';

// ✨ Magic: Shorebird Updater Initialization
final shorebirdUpdater = ShorebirdUpdater();

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. START UI IMMEDIATELY
    // We pass null for initialization results to show a booting screen
    runApp(
      const ProviderScope(
        child: MyApp(
          backendInitialized: false,
          isBooting: true,
        ),
      ),
    );

    bool backendInitialized = false;
    String? initializationError;

    try {
      // 2. LOAD SECRETS (with timeout)
      try {
        await dotenv.load(fileName: ".env").timeout(const Duration(seconds: 3));
        print('✅ DotEnv Loaded');
      } catch (e) {
        print('⚠️ DotEnv Load Skipped/Failed: $e');
      }

      // 3. INITIALIZE BACKEND (with timeout)
      await SupabaseService.initialize().timeout(const Duration(seconds: 10));
      backendInitialized = true;
      print('✅ Supabase initialized');
    } catch (e) {
      print('❌ Initialization failure: $e');
      initializationError = e.toString();
    }

    // 4. TRANSITION TO READY STATE
    runApp(
      ProviderScope(
        child: MyApp(
          backendInitialized: backendInitialized,
          initializationError: initializationError,
          isBooting: false,
        ),
      ),
    );
  }, (error, stack) {
    print('📦 FATAL GLOBAL ERROR: $error');
  });
}

class MyApp extends ConsumerStatefulWidget {
  final bool backendInitialized;
  final String? initializationError;
  final bool forceContinue;
  final bool isBooting;

  const MyApp({
    super.key,
    required this.backendInitialized,
    this.initializationError,
    this.forceContinue = false,
    this.isBooting = false,
  });

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Request permissions on app start
    _handleOnStartPermissions();
  }

  Future<void> _handleOnStartPermissions() async {
    // 1. Location Permission (Mandatory for Feed Distances)
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
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
    if (!widget.backendInitialized || !SupabaseService.instance.hasInitialized) return;
    
    final supabaseService = SupabaseService.instance;

    try {
      if (state == AppLifecycleState.resumed) {
        // App in foreground, set active and start timer
        ref.read(authProvider.notifier).toggleOnlineStatus(true);
        ref.read(authProvider.notifier).updateActivity();
      } else {
        // Paused, Inactive, or Detached (covers screen off and recent tabs)
        ref.read(authProvider.notifier).toggleOnlineStatus(false);
      }
    } catch (e) {
      print('Presence update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🛡️ SECURITY & STABILITY:
    // If we are booting, DO NOT watch any providers.
    // Provider observation triggers Supabase access which crashes during boot.
    if (widget.isBooting) {
      return MaterialApp(
        title: 'Happle',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Generic while booting
        debugShowCheckedModeBanner: false,
        home: _buildBootingScreen(),
      );
    }

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Happle',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: notificationMessengerKey,
      builder: (context, child) {
        if (!widget.backendInitialized && !widget.forceContinue) {
          return _buildOfflineScreen();
        }

        return Listener(
          onPointerDown: (_) => ref.read(authProvider.notifier).updateActivity(),
          onPointerMove: (_) => ref.read(authProvider.notifier).updateActivity(),
          child: BiometricLockWrapper(
            child: ASAPNotificationListener(
              child: Stack(
                children: [
                  child ?? const SizedBox.shrink(),
                  // ✨ Magic: Visual indicator for Shorebird Patch
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FutureBuilder<Patch?>(
                      future: shorebirdUpdater.readCurrentPatch(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Latest Patch #${snapshot.data!.number}',
                                style: const TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBootingScreen() {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.blue),
            SizedBox(height: 24),
            Text('Powering Up Happle...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
            SizedBox(height: 8),
            Text('STORAGE FIX v5: ACTIVE', style: TextStyle(color: Colors.blue, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('System Connection Failed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('We couldn\'t connect to the campus network.', textAlign: TextAlign.center),
              if (widget.initializationError != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: Text(widget.initializationError!, style: const TextStyle(color: Colors.red, fontSize: 10), textAlign: TextAlign.center),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => main(),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
                child: const Text('RETRY CONNECTION'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).logout(),
                child: const Text('RESET ACCOUNT'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BiometricLockWrapper extends ConsumerWidget {
  final Widget child;
  const BiometricLockWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.user != null;
    final isBiometricDone = authState.isBiometricAuthenticated;
    final isVerified = authState.user?.verified ?? false;

    // ✨ Magic: Get current path to whitelist onboarding
    String location = '';
    try {
      // Use the router provider to get location reliably even above navigator
      location = ref.read(routerProvider).routeInformationProvider.value.uri.path;
    } catch (_) {}

    final isOnboarding = location == '/kyc-verification' || 
                         location == '/check-in' || 
                         location == '/login' || 
                         location == '/signup' || 
                         location == '/profile/settings' ||
                         location == '/reset-password';

    // ✨ Magic: Don't lock if user is not verified yet (allow KYC flow) OR if on onboarding screens
    if (isAuthenticated && !isBiometricDone && isVerified && !isOnboarding) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_person_rounded, size: 80, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Happle Secured',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).authenticateWithBiometrics(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('AUTHENTICATE'),
              ),
               const SizedBox(height: 16),
               TextButton(
                 onPressed: () => ref.read(authProvider.notifier).logout(),
                 child: const Text('Logout', style: TextStyle(color: Colors.white38)),
               ),
            ],
          ),
        ),
      );
    }

    return child;
  }
}

final GlobalKey<ScaffoldMessengerState> notificationMessengerKey = GlobalKey<ScaffoldMessengerState>();

// routerProvider moved to lib/config/router.dart

