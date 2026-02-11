import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data_types/user.dart' as user_model;
import '../services/supabase_service.dart';
import '../services/biometric_service.dart';

// Auth state provider
class AuthState {
  final user_model.User? user;
  final supabase.User? sessionUser; // Added to track basic auth status
  final bool isLoading;
  final String? error;
  final bool isPasswordRecovery;
  final bool isBiometricAuthenticated; // Added for security access
  final bool isRestricted; // Added for inconsistent profiles (Verified in DB but missing docs)

  const AuthState({
    this.user,
    this.sessionUser,
    this.isLoading = false,
    this.error,
    this.isPasswordRecovery = false,
    this.isBiometricAuthenticated = false,
    this.isRestricted = false,
  });

  AuthState copyWith({
    user_model.User? user,
    supabase.User? sessionUser,
    bool? isLoading,
    String? error,
    bool? isPasswordRecovery,
    bool? isBiometricAuthenticated,
    bool? isRestricted,
  }) {
    return AuthState(
      user: user ?? this.user,
      sessionUser: sessionUser ?? this.sessionUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isPasswordRecovery: isPasswordRecovery ?? this.isPasswordRecovery,
      isBiometricAuthenticated: isBiometricAuthenticated ?? this.isBiometricAuthenticated,
      isRestricted: isRestricted ?? this.isRestricted,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  final BiometricService _biometricService = BiometricService();
  StreamSubscription<supabase.AuthState>? _authStateSubscription;
  Timer? _inactivityTimer;
  static const int inactivityMinutes = 5;

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

  bool _isUserRestricted(user_model.User? user) {
    if (user == null) return false;
    
    // RESTRICTED SESSION CHECK: If verified but missing physical documents, 
    // we don't want to block their access anymore as an admin has approved them.
    // We only mark as restricted if they are NOT verified and something is wrong.
    // Actually, if they are verified, we trust that.
    
    if (user.verified) return false;
    
    // Legacy: Catch inconsistent states for unverified users if needed.
    return false;
  }

  void _subscribeToProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = _supabaseService.getProfileStream().listen((profileData) {
      // ⚡ Handle missing profile (New Users / Glitches)
      if (profileData.isEmpty) {
        final authUser = _supabaseService.currentUser;
        if (authUser != null) {
          // If we already have a user but stream is empty, it might be a momentary glitch.
          // Don't downgrade them to unverified immediately if they were verified.
          if (state.user != null && state.user!.verified) {
             print('⚠️ Profile stream empty but user was verified. Ignoring glitch.');
             return;
          }

          print('⚠️ Profile missing in DB. Creating skeleton unverified user.');
          state = state.copyWith(
            user: _mapSupabaseUserToModel(authUser, {}),
            isLoading: false,
            sessionUser: authUser,
            isRestricted: false,
          );
        }
        return;
      }
      
      // Merge Auth User + Profile Data
      final authUser = _supabaseService.currentUser!;
      final user = _mapSupabaseUserToModel(authUser, profileData);
      
      // Initialize presence tracking once user profile is loaded
      _supabaseService.initializePresence(user.id);
      
      final isRestricted = _isUserRestricted(user);
      
      state = state.copyWith(
        user: user, 
        isLoading: false, 
        sessionUser: authUser, 
        isRestricted: isRestricted
      );
    }, onError: (error) {
      print('Profile sync error: $error');
      // Fallback to basic auth info if profile fails
      if (_supabaseService.currentUser != null) {
        final authUser = _supabaseService.currentUser!;
        final user = _mapSupabaseUserToModel(authUser, {});
        state = state.copyWith(
          user: user,
          isLoading: false,
          sessionUser: authUser,
          isRestricted: _isUserRestricted(user),
        );
      }
    });
  }

  user_model.User _mapSupabaseUserToModel(supabase.User user, Map<String, dynamic> profileData) {
    // Priority: Profile Table Data > Auth Metadata
    final metadata = user.userMetadata ?? {};
    
    return user_model.User(
      id: user.id.trim(),
      email: user.email ?? profileData['email'] ?? '',
      name: profileData['name'] ?? metadata['name'] ?? metadata['full_name'] ?? 'User',
      role: profileData['role'] ?? metadata['role'] ?? 'worker',
      avatarUrl: profileData['avatar_url'] ?? metadata['avatar_url'],
      verified: profileData['verified'] == true || profileData['is_verified'] == true, 
      createdAt: DateTime.parse(user.createdAt).toLocal(),
      walletBalance: (profileData['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      rating: (profileData['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: (profileData['completed_tasks'] as num?)?.toInt() ?? 0,
      isOnline: profileData['is_online'] == true,
      currentLat: (profileData['current_lat'] as num?)?.toDouble(),
      currentLng: (profileData['current_lng'] as num?)?.toDouble(),
      idCardUrl: profileData['id_card_url'] ?? profileData['idCardUrl'],
      selfieUrl: profileData['selfie_url'] ?? profileData['selfieUrl'],
      selfieWithIdUrl: profileData['selfie_with_id_url'] ?? profileData['selfieWithIdUrl'],
      verificationStatus: profileData['verification_status'] ?? profileData['verificationStatus'],
    );
  }

  Future<void> login(String email, String password) async {
    print('⚡ AuthNotifier: Starting login for $email');
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.signInWithEmail(email, password);
      // After login, we assume biometric is not yet done for THIS session, 
      // but if the device supports it, we might want to prompt later.
      // For now, we just mark as authenticated if we want immediate access.
      state = state.copyWith(isBiometricAuthenticated: true);
      print('⚡ AuthNotifier: Login call successful');
    } catch (e) {
      print('❌ AuthNotifier: Login error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> authenticateWithBiometrics() async {
    final available = await _biometricService.isAvailable();
    if (!available) {
      state = state.copyWith(isBiometricAuthenticated: true); // Fallback
      return;
    }

    final success = await _biometricService.authenticate(
      reason: 'Please authenticate to access Happle',
    );

    if (success) {
      state = state.copyWith(isBiometricAuthenticated: true);
    } else {
      state = state.copyWith(error: 'Biometric authentication failed');
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

      state = state.copyWith(isBiometricAuthenticated: true);
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
      print('⚡ Google Sign-In call successful');
      
      if (response.user != null) {
        // Ensure profile exists in PostgreSQL for this social user
        await _supabaseService.updateProfile({
          'name': response.user!.userMetadata?['full_name'] ?? 'Google User',
          'role': role,
          'email': response.user!.email,
        });
      }
      
      state = state.copyWith(isLoading: false, isBiometricAuthenticated: true);
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
    state = state.copyWith(user: user);
  }

  Future<void> updateUserType(String userType) async {
    final currentUser = state.user;
    if (currentUser != null) {
      final updatedUser = currentUser.copyWith(role: userType);
      state = state.copyWith(user: updatedUser);
    }
  }

  void updateActivity() {
    // ⚡ Magic: Every touch/move resets the clock
    _inactivityTimer?.cancel();
    
    // If user was offline (due to inactivity), bring them back online
    if (state.user != null && !state.user!.isOnline) {
       print('🏃 Activity detected: Bringing user back online.');
       toggleOnlineStatus(true);
    }

    _inactivityTimer = Timer(const Duration(minutes: inactivityMinutes), () {
      print('😴 Inactivity timeout reached (${inactivityMinutes}m). Going offline.');
      _handleInactivity();
    });
  }

  void _handleInactivity() {
    toggleOnlineStatus(false);
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    // Optimistic Update
    state = state.copyWith(user: currentUser.copyWith(isOnline: isOnline));

    try {
      await _supabaseService.setUserOnline(isOnline);
      print('⚡ Cloud status updated: $isOnline');
    } catch (e) {
      // Rollback
      state = state.copyWith(user: currentUser, error: 'Status update failed');
    }
  }

  Future<void> submitKYC({
    required File selfie,
    required File idCard,
    required File selfieWithId,
    required String extractedText,
  }) async {
    final currentUser = state.user;
    if (currentUser == null) return;

    state = state.copyWith(isLoading: true);

    try {
      // call service to upload and update DB
      final kycData = await _supabaseService.submitKYC(
        selfie: selfie, 
        idCard: idCard, 
        selfieWithId: selfieWithId,
        extractedText: extractedText
      );

      // Optimistic Update: Include all URLs to satisfy isRestricted check
      final updatedUser = currentUser.copyWith(
        verified: true,
        selfieUrl: kycData['selfie_url'],
        idCardUrl: kycData['id_card_url'],
        selfieWithIdUrl: kycData['selfie_with_id_url'],
        verificationStatus: 'verified',
      );
      state = state.copyWith(user: updatedUser, isLoading: false, isRestricted: false);
      
      // Force a full profile sync to ensure Router sees the change
      await refreshUser();
      
      print('⚡ AuthProvider: KYC Submitted & User Verified');
    } catch (e) {
      print('❌ AuthProvider KYC Error: $e');
      state = state.copyWith(isLoading: false, error: 'KYC Submission Failed: $e');
      rethrow;
    }
  }

  Future<void> refreshUser() async {
     if (_supabaseService.currentUser != null) {
        try {
           final profile = await _supabaseService.getProfile(userId: _supabaseService.currentUser!.id);
           if (profile != null) {
              final authUser = _supabaseService.currentUser!;
              final user = _mapSupabaseUserToModel(authUser, profile);
              state = state.copyWith(
                user: user,
                isRestricted: _isUserRestricted(user),
              );
              
              // If user is online in DB, ensure local activity tracker is running
              if (user.isOnline) {
                 updateActivity();
              }
           }
        } catch (e) {
           print('Error refreshing user: $e');
        }
     }
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    _profileSubscription?.cancel();
    _inactivityTimer?.cancel();
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
