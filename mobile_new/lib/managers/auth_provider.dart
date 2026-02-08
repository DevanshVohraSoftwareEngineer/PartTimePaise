import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data_types/user.dart' as user_model;
import '../services/supabase_service.dart';

// Auth state provider
class AuthState {
  final user_model.User? user;
  final supabase.User? sessionUser; // Added to track basic auth status
  final bool isLoading;
  final String? error;
  final bool isPasswordRecovery;

  const AuthState({
    this.user,
    this.sessionUser,
    this.isLoading = false,
    this.error,
    this.isPasswordRecovery = false,
  });

  AuthState copyWith({
    user_model.User? user,
    supabase.User? sessionUser,
    bool? isLoading,
    String? error,
    bool? isPasswordRecovery,
  }) {
    return AuthState(
      user: user ?? this.user,
      sessionUser: sessionUser ?? this.sessionUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;

  AuthNotifier(this._supabaseService) : super(const AuthState(isLoading: true)) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    print('⚡ Initializing Supabase auth listener...');

    // Proactively check current session to avoid stuck-at-loading
    if (!_supabaseService.hasInitialized) {
      print('⚠️ Supabase not initialized, skipping session check');
      state = const AuthState(isLoading: false);
      return;
    }

    final currentSession = _supabaseService.currentUser != null 
        ? supabase.Supabase.instance.client.auth.currentSession 
        : null;
    
    if (currentSession?.user != null) {
      print('⚡ Initial session found for: ${currentSession!.user.email}');
      state = state.copyWith(sessionUser: currentSession.user, isLoading: true);
      _subscribeToProfile(); // We need to subscribe to get the full profile including 'verified' status
    } else {
      print('⚡ No initial session found during proactive check, showing login');
      state = const AuthState(isLoading: false);
    }

    _authStateSubscription = _supabaseService.authStateChanges.listen((data) {
      final session = data.session;
      final event = data.event;

      if (event == supabase.AuthChangeEvent.passwordRecovery) {
        state = state.copyWith(isPasswordRecovery: true, isLoading: false);
        return;
      }
      
      if (session?.user != null) {
        // Update basic session info immediately
        state = state.copyWith(sessionUser: session!.user);
        // User is logged in, now fetch/listen to their specific PROFILE data
        _subscribeToProfile();
      } else {
        _profileSubscription?.cancel();
        state = const AuthState(isLoading: false, sessionUser: null, user: null);
      }
    }, onError: (error) {
      state = AuthState(error: error.toString(), isLoading: false);
    });
  }

  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  void _subscribeToProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = _supabaseService.getProfileStream().listen((profileData) {
      if (profileData.isEmpty) return;
      
      // Merge Auth User + Profile Data
      final authUser = _supabaseService.currentUser!;
      final user = _mapSupabaseUserToModel(authUser, profileData);
      
      state = AuthState(user: user, isLoading: false, sessionUser: authUser);
    }, onError: (error) {
      print('Profile sync error: $error');
      // Fallback to basic auth info if profile fails
      if (_supabaseService.currentUser != null) {
        state = AuthState(
          user: _mapSupabaseUserToModel(_supabaseService.currentUser!, {}),
          isLoading: false,
          sessionUser: _supabaseService.currentUser,
        );
      }
    });
  }

  user_model.User _mapSupabaseUserToModel(supabase.User user, Map<String, dynamic> profileData) {
    // Priority: Profile Table Data > Auth Metadata
    final metadata = user.userMetadata ?? {};
    
    return user_model.User(
      id: user.id,
      email: user.email ?? profileData['email'] ?? '',
      name: profileData['name'] ?? metadata['name'] ?? metadata['full_name'] ?? 'User',
      role: profileData['role'] ?? metadata['role'] ?? 'worker',
      avatarUrl: profileData['avatar_url'] ?? metadata['avatar_url'],
      college: profileData['college'] ?? metadata['college'],
      verified: profileData['verified'] == true, // Critical for KYC
      createdAt: DateTime.parse(user.createdAt).toLocal(),
      walletBalance: (profileData['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      rating: (profileData['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: (profileData['completed_tasks'] as num?)?.toInt() ?? 0,
      isOnline: profileData['is_online'] == true,
      currentLat: (profileData['current_lat'] as num?)?.toDouble(),
      currentLng: (profileData['current_lng'] as num?)?.toDouble(),
    );
  }

  Future<void> login(String email, String password) async {
    print('⚡ AuthNotifier: Starting login for $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.signInWithEmail(email, password);
      print('⚡ AuthNotifier: Login call successful');
    } catch (e) {
      print('❌ AuthNotifier: Login error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    print('⚡ AuthNotifier: Requesting password reset for $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('❌ AuthNotifier: Reset password error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updatePassword(String newPassword) async {
    print('⚡ AuthNotifier: Updating password');
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.updatePassword(newPassword);
      state = state.copyWith(isLoading: false, isPasswordRecovery: false); // Clear redirect flag
    } catch (e) {
      print('❌ AuthNotifier: Update password error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void clearRecoveryFlag() {
    state = state.copyWith(isPasswordRecovery: false);
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? college,
  }) async {
    print('⚡ AuthNotifier: Starting registration for $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userData = {
        'name': name,
        'role': role,
        'college': college,
      };

      final response = await _supabaseService.signUpWithEmail(email, password, userData);
      print('⚡ AuthNotifier: Registration call successful, user ID: ${response.user?.id}');
      
      // Create profile in the 'profiles' table for "realtime magic"
      if (response.user != null) {
        try {
          await _supabaseService.updateProfile({
            'name': name,
            'role': role,
            'college': college,
            'email': email,
          });
          print('⚡ AuthNotifier: Profile created successfully');
        } catch (profileError) {
          print('⚡ AuthNotifier: Profile creation failed: $profileError');
          // Don't fail registration if profile creation fails
          // The profile will be created when needed (e.g., when posting first task)
        }
      }

      // Check if session is null (meaning email confirmation might be required)
      if (response.session == null && response.user != null) {
        state = state.copyWith(isLoading: false, error: 'CONFIRMATION_REQUIRED');
        throw Exception('Please check your email to confirm your account.');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> signInWithGoogle(String role) async {
    print('⚡ AuthNotifier: Starting Google Sign-In');
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _supabaseService.signInWithGoogle();
      print('⚡ AuthNotifier: Google Sign-In call successful');
      
      if (response.user != null) {
        // Ensure profile exists in PostgreSQL for this social user
        await _supabaseService.updateProfile({
          'name': response.user!.userMetadata?['full_name'] ?? 'Google User',
          'role': role,
          'email': response.user!.email,
        });
      }
      
      state = state.copyWith(isLoading: false);
    } catch (e) {
      print('⚡ Google Sign-In Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> signInWithFacebook(String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Placeholder for Facebook Sign-In
      state = state.copyWith(isLoading: false, error: 'Facebook Sign-In needs configuration');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateUser(user_model.User user) async {
    state = AuthState(user: user);
  }

  Future<void> updateUserType(String userType) async {
    final currentUser = state.user;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(role: userType);
      state = AuthState(user: updatedUser);
    }
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    // Optimistic Update
    state = state.copyWith(user: currentUser.copyWith(isOnline: isOnline));

    // For debug users, we STILL update the DB because they now have profiles!
    // This ensures real-time matching works for them too.
    try {
      await _supabaseService.updateProfile({'is_online': isOnline});
      print('⚡ Cloud status updated: $isOnline');
    } catch (e) {
      // Rollback
      print('❌ Failed to update status: $e');
      state = state.copyWith(user: currentUser, error: 'Status update failed');
    }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _profileSubscription?.cancel();
    super.dispose();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return AuthNotifier(supabaseService);
});

// Computed providers
final currentUserProvider = Provider<user_model.User?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).user != null;
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.role;
});
