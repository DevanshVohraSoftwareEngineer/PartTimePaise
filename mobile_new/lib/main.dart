import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/supabase_service.dart';
import 'config/theme.dart';
import 'managers/auth_provider.dart';
import 'managers/theme_provider.dart';
import 'widgets/asap_notification_listener.dart';
import 'config/router.dart';

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
    super.key,
    required this.backendInitialized,
    this.initializationError,
    this.forceContinue = false,
  });

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
        // ALWAYS set online when app is in foreground/being used
        supabaseService.setUserOnline(true);
      } else if (state == AppLifecycleState.paused || state == AppLifecycleState.detached || state == AppLifecycleState.inactive) {
        // STRICT: Set offline when not strictly in foreground
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
      title: 'Happle',
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

// routerProvider moved to lib/config/router.dart

