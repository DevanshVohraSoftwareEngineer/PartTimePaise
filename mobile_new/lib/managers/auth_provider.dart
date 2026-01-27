import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../data_types/user.dart' as user_model;
import '../services/supabase_service.dart';

// Auth state provider
class AuthState {
  final user_model.User? user;
  final supabase.User? sessionUser; 
  final bool isLoading;
  final String? error;

  const AuthState({
    this.user,
    this.sessionUser,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    user_model.User? user,
    supabase.User? sessionUser,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      sessionUser: sessionUser ?? this.sessionUser,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseService _supabaseService;
  StreamSubscription<supabase.AuthState>? _authStateSubscription;
  StreamSubscription<Map<String, dynamic>>? _profileSubscription;

  AuthNotifier(this._supabaseService) : super(const AuthState(isLoading: true)) {
    _initializeAuthListener();
  }

  void _initializeAuthListener() {
    // ✨ Magic: Safety check for Supabase initialization
    try {
      if (!_supabaseService.hasInitialized) {
        state = const AuthState(isLoading: false);
        return;
      }

      // Check current session safely
      final currentUser = _supabaseService.currentUser;
      if (currentUser != null) {
        state = state.copyWith(sessionUser: currentUser, isLoading: true);
        _subscribeToProfile();
      } else {
        state = const AuthState(isLoading: false);
      }

      // Listen for future auth changes
      _authStateSubscription = _supabaseService.authStateChanges.listen((data) {
        final session = data.session;
        if (session?.user != null) {
          state = state.copyWith(sessionUser: session!.user);
          _subscribeToProfile();
        } else {
          _profileSubscription?.cancel();
          state = const AuthState(isLoading: false, sessionUser: null, user: null);
        }
      }, onError: (error) {
        print('Auth listener error: $error');
        state = AuthState(error: error.toString(), isLoading: false);
      });

    } catch (e) {
      print('❌ AuthNotifier Fatal Init Error: $e');
      state = AuthState(error: e.toString(), isLoading: false);
    }
  }

  void _subscribeToProfile() {
    _profileSubscription?.cancel();
    _profileSubscription = _supabaseService.getProfileStream().listen((profileData) {
      if (profileData.isEmpty) return;
      
      final authUser = _supabaseService.currentUser;
      if (authUser == null) return;
      
      final user = _mapSupabaseUserToModel(authUser, profileData);
      
      // Init presence AFTER we have a confirmed profile
      _supabaseService.initializePresence(user.id);
      
      state = AuthState(user: user, isLoading: false, sessionUser: authUser);
    }, onError: (error) {
       print('Profile sync error: $error');
       final authUser = _supabaseService.currentUser;
       if (authUser != null) {
         state = AuthState(
           user: _mapSupabaseUserToModel(authUser, {}),
           isLoading: false,
           sessionUser: authUser,
         );
       }
    });
  }

  user_model.User _mapSupabaseUserToModel(supabase.User user, Map<String, dynamic> profileData) {
    final metadata = user.userMetadata ?? {};
    return user_model.User(
      id: user.id,
      email: user.email ?? profileData['email'] ?? '',
      name: profileData['name'] ?? metadata['name'] ?? metadata['full_name'] ?? 'User',
      role: profileData['role'] ?? metadata['role'] ?? 'worker',
      avatarUrl: profileData['avatar_url'] ?? metadata['avatar_url'],
      college: profileData['college'] ?? metadata['college'],
      verified: profileData['verified'] == true,
      createdAt: DateTime.parse(user.createdAt),
      walletBalance: (profileData['wallet_balance'] as num?)?.toDouble() ?? 0.0,
      rating: (profileData['rating'] as num?)?.toDouble() ?? 0.0,
      completedTasks: (profileData['completed_tasks'] as num?)?.toInt() ?? 0,
      isOnline: profileData['is_online'] == true,
      idCardUrl: profileData['id_card_url'],
      selfieUrl: profileData['selfie_url'],
      verificationStatus: profileData['verification_status'],
    );
  }

  String _mapErrorToMessage(dynamic e) {
    final errorStr = e.toString().toLowerCase();
    
    // 1. Precise Network Unreachable (Errno 101/SocketException)
    if (errorStr.contains('network is unreachable') || 
        errorStr.contains('socketexception') ||
        errorStr.contains('errno = 101') ||
        errorStr.contains('connection failed')) {
      return '📡 Network Unreachable. Please check your internet connection or Wi-Fi and try again.';
    }

    // 2. Supabase Auth specific
    if (errorStr.contains('authretryablefetchexception')) {
      return '🔄 Connection lost while contacting server. Retrying... (Check your internet)';
    }

    if (errorStr.contains('invalid login credentials')) {
      return '🔑 Incorrect email or password. Please try again.';
    }

    if (errorStr.contains('email not confirmed')) {
      return '📧 Please confirm your email address before logging in.';
    }

    // Default fallback
    return '❌ Authentication Error: ${e.toString().split(':').last.trim()}';
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _supabaseService.signInWithEmail(email, password);
    } catch (e) {
      final message = _mapErrorToMessage(e);
      state = state.copyWith(isLoading: false, error: message);
      throw Exception(message);
    }
  }

  Future<void> logout() async {
    try {
      await toggleOnlineStatus(false);
      await _supabaseService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleOnlineStatus(bool isOnline) async {
    final currentUser = state.user;
    if (currentUser == null) return;
    state = state.copyWith(user: currentUser.copyWith(isOnline: isOnline));
    try {
      await _supabaseService.updateProfile({'is_online': isOnline});
    } catch (e) {
      state = state.copyWith(user: currentUser, error: 'Status update failed');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String role,
    String? college,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userData = {
        'name': name,
        'role': role,
        'college': college,
      };

      final response = await _supabaseService.signUpWithEmail(email, password, userData);
      
      if (response.user != null) {
        try {
          await _supabaseService.updateProfile({
            'name': name,
            'role': role,
            'college': college,
            'email': email,
          });
        } catch (profileError) {
          print('Profile creation failed: $profileError');
        }
      }

      if (response.session == null && response.user != null) {
        state = state.copyWith(isLoading: false, error: 'CONFIRMATION_REQUIRED');
        throw Exception('Please check your email to confirm your account.');
      }
    } catch (e) {
      final message = _mapErrorToMessage(e);
      state = state.copyWith(isLoading: false, error: message);
      throw Exception(message);
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

  void bypass() {
    final mockUser = user_model.User(
      id: 'debug-user-id',
      email: 'debug@example.com',
      name: 'Debug User',
      role: 'worker',
      verified: true,
      createdAt: DateTime.now(),
    );

    state = AuthState(
      user: mockUser,
      sessionUser: const supabase.User(
        id: 'debug-user-id',
        email: 'debug@example.com',
        appMetadata: {},
        userMetadata: {'full_name': 'Debug User'},
        aud: 'authenticated',
        createdAt: '',
      ),
      isLoading: false,
    );
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
