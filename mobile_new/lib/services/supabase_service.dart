import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:io';
import '../data_types/earnings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:app_links/app_links.dart';

class SupabaseService {
  static SupabaseService? _instance;
  static SupabaseService get instance {
    _instance ??= SupabaseService._internal();
    return _instance!;
  }

  SupabaseService._internal();

  final _supabase = Supabase.instance.client;
  SupabaseClient get client => _supabase;

  // Presence Management
  RealtimeChannel? _presenceChannel;
  final _presenceController = StreamController<int>.broadcast();
  Stream<int> get onlineCountStream => _presenceController.stream;

  // Configuration (Placeholders - MUST BE REPLACED)
  static const String supabaseUrl = 'https://jonahejqfgeqtkdyscnq.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImpvbmFoZWpxZmdlcXRrZHlzY25xIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkxODQ4NDIsImV4cCI6MjA4NDc2MDg0Mn0.VnpNJeKceNEu8p3Ji1Q4eb_m_C0Po1mhIVQ9lySuEFQ';

  // Deep Link Management
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  // Initialize Supabase
  static Future<void> initialize() async {
    print('🚀 Initializing Supabase with Fortified Network Stack...');
    
    // Add a small retry loop for DNS/Socket issues during startup
    int retryCount = 0;
    while (retryCount < 3) {
      try {
        await Supabase.initialize(
          url: supabaseUrl.trim().toLowerCase(), // Defensive: trim and lowercase
          anonKey: supabaseAnonKey,
          debug: kDebugMode,
        );
        
        // Setup manual link handling for iOS robust recovery
        instance._initDeepLinks();
        
        print('✅ Supabase Network Stack Initialized Successfully');
        return;
      } catch (e) {
        retryCount++;
        print('⚠️ Supabase Initialization Attempt $retryCount failed: $e');
        if (retryCount >= 3) {
          print('❌ Supabase Initialization failed after 3 attempts.');
          rethrow;
        }
        if (e.toString().contains('SocketException') || e.toString().contains('host lookup')) {
           print('🔄 Potential DNS/Socket issue detected. Retrying in 2 seconds...');
           await Future.delayed(const Duration(seconds: 2));
        } else {
           rethrow; 
        }
      }
    }
  }

  void _initDeepLinks() {
    _appLinks = AppLinks();

    // Check for cold start link
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        print('⚡ Cold Start Deep Link Received: $uri');
        _handleIncomingLink(uri);
      }
    });

    // Listen for incoming links while app is open
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      print('⚡ Incoming Deep Link Received: $uri');
      _handleIncomingLink(uri);
    }, onError: (err) {
      print('❌ Deep Link Error: $err');
    });
  }

  void _handleIncomingLink(Uri uri) {
    // Pipe the link into Supabase manually
    // This solves the issue where iOS doesn't automatically pass links to Supabase
    // particularly when using custom schemes like parttimepaise://
    if (uri.toString().contains('type=recovery') || uri.toString().contains('code=')) {
      print('🔑 Processing Recovery/Auth Link for iPhone...');
      _supabase.auth.getSessionFromUrl(uri); 
    }
  }

  // Helper for retrying network-sensitive operations
  Future<T> _withRetry<T>(Future<T> Function() operation) async {
    int attempts = 0;
    while (true) {
      try {
        return await operation();
      } catch (e) {
        attempts++;
        final errorStr = e.toString().toLowerCase();
        if (attempts < 3 && (errorStr.contains('socketexception') || errorStr.contains('host lookup') || errorStr.contains('clientexception'))) {
          print('🔄 Socket/Network error. Retry attempt $attempts...');
          await Future.delayed(Duration(seconds: attempts * 2));
          continue;
        }
        rethrow;
      }
    }
  }

  bool get hasInitialized {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  // --- AUTH METHODS ---
  
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    print('🔑 Supabase: signInWithEmail for $email');
    return _withRetry(() => _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    ));
  }

  Future<void> resetPasswordForEmail(String email) async {
    print('🔑 Supabase: resetPasswordForEmail for $email');
    await _withRetry(() => _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : 'parttimepaise://reset-password',
    ));
  }

  Future<UserResponse> updatePassword(String newPassword) async {
    print('🔑 Supabase: updatePassword');
    return _withRetry(() => _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    ));
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, Map<String, dynamic> userData) async {
    print('🔑 Supabase: signUpWithEmail for $email');
    return _withRetry(() => _supabase.auth.signUp(
      email: email,
      password: password,
      data: userData,
    ));
  }

  Future<AuthResponse> signInWithGoogle() async {
    print('🔑 Supabase: signInWithGoogle starting');
    // --- Google Sign-In Implementation ---
    // Web Client ID (from Supabase Auth -> Providers -> Google)
    const webClientId = '1052880873534-o8f26fvr9ffel0ctaha91vp39rjdsdst.apps.googleusercontent.com';
    
    // Android Client ID (from Google Cloud Console -> Credentials - UPDATED with correct SHA-1)
    const androidClientId = '1052880873534-d699an6aevb1i00tjivftjutmalpm6ch.apps.googleusercontent.com';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: kIsWeb ? webClientId : androidClientId,
      serverClientId: webClientId, // Required to get idToken on Android/iOS
    );
    
    print('🔑 Supabase: Calling googleSignIn.signIn()');
    final googleUser = await googleSignIn.signIn();
    print('🔑 Supabase: Google User: ${googleUser?.email}');
    
    final googleAuth = await googleUser?.authentication;
    final accessToken = googleAuth?.accessToken;
    final idToken = googleAuth?.idToken;

    if (idToken == null) {
      print('❌ Supabase: No ID Token found');
      throw 'No ID Token found.';
    }

    print('🔑 Supabase: Calling signInWithIdToken');
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    print('🔑 Supabase: Google Sign-In response received');
    return response;
  }

  Future<void> signOut() async {
    await _presenceChannel?.unsubscribe();
    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;
  Session? get currentSession => _supabase.auth.currentSession;
  
  String? get currentUserId => _supabase.auth.currentUser?.id;

  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // --- DATABASE METHODS (Instant Dispatch) ---

  // Update a task
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    await _supabase.from('tasks').update(data).eq('id', taskId);
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _supabase.from('tasks').delete().eq('id', taskId);
  }

  Stream<List<Map<String, dynamic>>> getTasksStream() {
    return _supabase
        .from('tasks')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // Create a new task
  Future<void> createTask(Map<String, dynamic> taskData) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Ensure user profile exists before creating task
    await _ensureProfileExists();

    await _supabase.from('tasks').insert({
      ...taskData,
      'client_id': userId,
      'status': 'open',
    });
  }

  /// Manually trigger task assignment for a task
  /// This can be called if the automatic trigger is disabled or for retries
  Future<void> assignTaskToNearestWorker(String taskId) async {
    try {
      // We can call a Postgres RPC function for efficiency
      await _supabase.rpc('assign_nearest_worker', params: {'p_task_id': taskId});
      print('✅ Task $taskId assignment check completed');
    } catch (e) {
      print('❌ Task Assignment Error: $e');
      rethrow;
    }
  }

  /// Fetch earnings summary for the current worker
  Future<WorkerEarningsSummary> getWorkerEarningsSummary() async {
    final workerId = currentUserId;
    if (workerId == null) throw Exception('User not authenticated');

    try {
      // 1. Fetch task-wise earnings from view
      final earningsResponse = await _supabase
          .from('worker_earnings_summary')
          .select()
          .eq('worker_id', workerId)
          .order('completed_at', ascending: false);

      final taskEarnings = (earningsResponse as List)
          .map((json) => TaskEarnings.fromJson(json))
          .toList();

      // 2. Fetch milestone incentives from RPC
      final incentiveResponse = await _supabase.rpc(
        'get_worker_milestone_incentives',
        params: {'p_worker_id': workerId},
      );

      final milestoneIncentives = (incentiveResponse as num?)?.toDouble() ?? 0.0;
      final totalTaskEarnings = taskEarnings.fold(0.0, (sum, item) => sum + item.totalTaskEarnings);

      return WorkerEarningsSummary(
        taskEarnings: taskEarnings,
        totalTaskEarnings: totalTaskEarnings,
        milestoneIncentives: milestoneIncentives,
        grandTotal: totalTaskEarnings + milestoneIncentives,
      );
    } catch (e) {
      print('❌ Error fetching earnings: $e');
      rethrow;
    }
  }

  /// Update user availability
  Future<void> setAvailability(bool isOnline) async {
    try {
      await _supabase.rpc('set_student_availability', params: {'p_is_online': isOnline});
      print('✅ Availability set to: ${isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      print('❌ Error setting availability: $e');
      rethrow;
    }
  }

  /// Send lightness heartbeat to keep user online
  Future<void> sendHeartbeat() async {
    try {
      await _supabase.rpc('update_student_heartbeat');
    } catch (e) {
      print('❌ Heartbeat failed: $e');
    }
  }

  // Ensure user profile exists in profiles table
  Future<void> _ensureProfileExists() async {
    final user = currentUser;
    final userId = user?.id;
    if (userId == null) return;

    final userMetadata = user?.userMetadata ?? {};

    // Check if profile exists
    final existingProfile = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existingProfile == null) {
      // Create profile if it doesn't exist
      await _supabase.from('profiles').insert({
        'id': userId,
        'name': userMetadata['name'] ?? userMetadata['full_name'] ?? 'User',
        'email': user?.email ?? '',
        'role': userMetadata['role'] ?? 'worker',
        'college': userMetadata['college'] ?? 'Student',
        'created_at': user?.createdAt ?? DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    }
  }

  // Swipe logic (Relational version)
  Future<void> createSwipe(String taskId, String direction) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _supabase.from('swipes').upsert(
      {
        'task_id': taskId,
        'user_id': userId,
        'direction': direction,
      },
      onConflict: 'user_id, task_id', // Explicitly handle conflict on unique constraint
    );
    
    // In a real app, a Postgres Trigger would handle match creation automatically
  }

  Future<Set<String>> getUserSwipedTaskIds() async {
    final userId = currentUserId;
    if (userId == null) return {};

    try {
      final response = await _supabase
          .from('swipes')
          .select('task_id')
          .eq('user_id', userId);

      return (response as List)
          .map((row) => row['task_id'].toString())
          .toSet();
    } catch (e) {
      print('Error fetching swipes: $e');
      return {};
    }
  }

  // Chat/Messages Real-time
  Stream<List<Map<String, dynamic>>> getMessagesStream(String matchId) {
    return _supabase
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('match_id', matchId)
        .order('created_at', ascending: true);
  }

  Future<void> sendMessage(String matchId, String content, {String type = 'text'}) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _supabase.from('chat_messages').insert({
      'match_id': matchId,
      'sender_id': userId,
      'content': content,
      'type': type,
    });
  }

  Future<String?> uploadChatMedia(String matchId, File file) async {
    final userId = currentUserId;
    if (userId == null) return null;

    final fileExt = file.path.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    final path = 'chat_media/$matchId/$fileName';

    try {
      await _supabase.storage.from('chat_assets').upload(path, file);
      return _supabase.storage.from('chat_assets').getPublicUrl(path);
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }

  // --- TYPING INDICATORS (Broadcast) ---
  RealtimeChannel getTypingChannel(String matchId) {
    return _supabase.channel('typing:$matchId');
  }

  Future<void> setTypingStatus(String matchId, bool isTyping) async {
    final userId = currentUserId;
    if (userId == null) return;

    final channel = getTypingChannel(matchId);
    // ignore: invalid_use_of_internal_member
    await channel.send(
      type: 'broadcast' as dynamic,
      event: 'typing',
      payload: {'userId': userId, 'isTyping': isTyping},
    );
  }

  // --- CALL SIGNALING (Broadcast) ---
  Future<void> sendCallSignal({
    required String targetUserId,
    required String matchId,
    required bool isVoiceOnly,
  }) async {
    final userId = currentUserId;
    if (userId == null) return;

    final channel = _supabase.channel('user_calls:$targetUserId');
    
    // ✨ Magic: In Supabase v2, we can send broadcast without manual subscribe if we just want to push
    // However, some versions/configurations expect a subscription to the local instance.
    // We'll use the most robust approach.
    channel.subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        await channel.sendBroadcastMessage(
          event: 'incoming_call',
          payload: {
            'callerId': userId,
            'callerName': currentUser?.userMetadata?['name'] ?? 'User',
            'callerAvatar': currentUser?.userMetadata?['avatar_url'],
            'isVoiceOnly': isVoiceOnly,
            'matchId': matchId,
          },
        );
        print('📞 Call Signal Sent to $targetUserId');
        
        // Unsubscribe after sending to keep connection pool clean
        Timer(const Duration(seconds: 5), () => channel.unsubscribe());
      } else if (status == RealtimeSubscribeStatus.channelError) {
        print('❌ Call Signal Subscription Error: $error');
      }
    });
  }

  // Notifications Real-time
  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _supabase
        .from('notifications')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false);
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId);
  }

  Future<void> archiveNotification(String notificationId) async {
    await _supabase
        .from('notifications')
        .update({'is_archived': true})
        .eq('id', notificationId);
  }

  // Matches Real-time (Participants only)
  Stream<List<Map<String, dynamic>>> getMatchesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    // Listen directly to matches table for best reliability
    // Hydration happens in the Provider
    return _supabase
        .from('matches')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  // ZOMATO ARCHITECTURE: Listen for selective offerings
  Stream<List<Map<String, dynamic>>> getPendingGigRequestsStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    return _supabase
        .from('gig_requests')
        .stream(primaryKey: ['id'])
        .eq('worker_id', userId);
  }

  // Incoming Swipes (Client Perspective: Who liked my tasks?)
  // Note: relying on client-side filtering or a view if complex joins needed.
  // For now, we assume we fetch swipes where task->client_id = me.
  Stream<List<Map<String, dynamic>>> getIncomingSwipesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);

    // Logic: 
    // 1. We need swipes on tasks where client_id = current_user
    // 2. Since stream filter on joined table is hard, we might need a specific query or Edge Function.
    // Hack for Demo: Stream ALL swipes, filter locally (Not scalable but works for demo).
    // Better Hack: Stream 'swipes' and we'll filter in the Provider by fetching my tasks.
    return _supabase
        .from('swipes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list.where((item) => item['direction'] == 'right').toList());
  }

  // Applied Swipes (Worker Perspective: Tasks I swiped right on)
  Stream<List<Map<String, dynamic>>> getMyAppliedSwipesStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value([]);
    
    return _supabase
        .from('swipes')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((list) => list.where((item) => 
            item['user_id'] == userId && 
            item['direction'] == 'right'
          ).toList());
  }

  Future<String> createMatch(String taskId, String workerId) async {
    final clientId = currentUserId;
    if (clientId == null) throw Exception('Not logged in');

    // 1. Create the Match
    final matchRes = await _supabase.from('matches').insert({
      'task_id': taskId,
      'client_id': clientId,
      'worker_id': workerId,
      'status': 'active',
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    final String matchId = matchRes['id'];

    // 2. Create initial "Match" system message or notification
    await sendMessage(matchId, "You matched! Start the conversation.", type: 'system');
    
    return matchId;
  }

  Future<void> rejectCandidate(String taskId, String workerId) async {
    await _supabase.from('swipes')
        .update({'direction': 'left'})
        .eq('task_id', taskId)
        .eq('user_id', workerId);
  }

  /// Permanently removes swipes older than 60 minutes from the database
  Future<void> deleteExpiredSwipes() async {
    try {
      final userId = currentUserId;
      if (userId == null) return;
      
      final now = DateTime.now();
      final sixtyMinsAgo = now.subtract(const Duration(minutes: 60)).toIso8601String();
      
      // Delete ONLY the current user's expired swipes to avoid RLS permission errors
      await _supabase
          .from('swipes')
          .delete()
          .eq('user_id', userId)
          .lt('created_at', sixtyMinsAgo);
          
      print('🧹 Scoped cleanup: Current user\'s expired swipes removed from SQL');
    } catch (e) {
      print('❌ Error during SQL cleanup of expired swipes: $e');
    }
  }

  // Bids Real-time
  Stream<List<Map<String, dynamic>>> getBidsStream(String taskId) {
    return _supabase
        .from('bids')
        .stream(primaryKey: ['id'])
        .eq('task_id', taskId)
        .order('created_at', ascending: false);
  }

  Future<void> submitBid(String taskId, double amount, String message) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _supabase.from('bids').insert({
      'task_id': taskId,
      'worker_id': userId,
      'amount': amount,
      'message': message,
      'status': 'pending',
    });
  }

  Future<void> updateBidStatus(String bidId, String status) async {
    await _supabase
        .from('bids')
        .update({'status': status})
        .eq('id', bidId);
  }

  Future<void> updateProfile(Map<String, dynamic> profileData) async {
    final userId = currentUserId;
    if (userId == null) return;

    // Use a selective update to avoid overwriting fields we didn't intend to
    await _supabase.from('profiles').update({
      ...profileData,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // --- PRESENCE METHODS ---

  Future<void> initializePresence(String userId) async {
    if (_presenceChannel != null) return;
    
    print('🌐 Initializing Supabase Presence for $userId');
    _presenceChannel = _supabase.channel('global_presence', opts: const RealtimeChannelConfig(self: true));

    _presenceChannel!.onPresenceSync((payload) {
      final onlineUsers = _presenceChannel!.presenceState();
      int count = onlineUsers.length;
      print('🌐 Presence Sync: $count users online');
      _presenceController.add(count);
    }).subscribe((status, [error]) async {
      if (status == RealtimeSubscribeStatus.subscribed) {
        print('🌐 Presence Channel Subscribed');
        await _presenceChannel!.track({
          'user_id': userId,
          'online_at': DateTime.now().toIso8601String(),
        });
      }
    });

    // Mark as online immediately
    await setUserOnline(true);
  }

  Future<void> setUserOnline(bool isOnline) async {
    final userId = currentUserId;
    if (userId == null) return;

    try {
      await _supabase.from('profiles').update({
        'is_online': isOnline,
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', userId);
      print('🌐 Presence: User set to ${isOnline ? 'Online' : 'Offline'}');
    } catch (e) {
      print('❌ Error setting user online status: $e');
    }
  }

  // --- ROOM-SPECIFIC PRESENCE (Snapchat Style) ---

  RealtimeChannel getChatPresenceChannel(String matchId) {
    return _supabase.channel('chat_presence:$matchId', opts: const RealtimeChannelConfig(self: true));
  }

  Future<void> updateLocation(double lat, double lng) async {
    final userId = currentUserId;
    if (userId == null) return;

    await _supabase.from('profiles').update({
      'current_lat': lat,
      'current_lng': lng,
      'last_location_update': DateTime.now().toIso8601String(),
    }).eq('id', userId);
  }

  // Profile Real-time
  Stream<Map<String, dynamic>> getProfileStream() {
    final userId = currentUserId;
    if (userId == null) return Stream.value({});

    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .limit(1)
        .map((data) => data.isNotEmpty ? data.first : {});
  }

  // Stream for global online count (Database source of truth)
  Stream<int> get globalOnlineCountStream {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('is_online', true)
        .map((list) => list.length);
  }

  // Stream for online users
  Stream<List<Map<String, dynamic>>> getOnlineUsersStream() {
    return _supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('is_online', true);
  }

  // --- SAFETY & KYC ---
  Future<Map<String, dynamic>?> getKYCVerification(String targetUserId) async {
    try {
      final data = await _supabase
          .from('id_verifications')
          .select('id_card_url, selfie_url, status, updated_at')
          .eq('user_id', targetUserId)
          .eq('status', 'verified') // Only show if verified
          .maybeSingle();
      return data;
    } catch (e) {
      print('❌ Error fetching KYC data: $e');
      return null;
    }
  }

  // --- ANALYTICS TRACKING ---
  Future<void> trackTaskView(String taskId) async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _supabase.rpc('track_task_view', params: {
        't_id': taskId,
        'u_id': userId,
      });
    } catch (e) {
      print('❌ Error tracking task view: $e');
    }
  }

  Future<void> updateRealtimeViewers(String taskId, int delta) async {
    try {
      await _supabase.rpc('update_realtime_viewers', params: {
        't_id': taskId,
        'increment_val': delta,
      });
    } catch (e) {
      print('❌ Error updating realtime viewers: $e');
    }
  }
}

// Provider for Riverpod integration
final supabaseServiceProvider = Provider((ref) => SupabaseService.instance);
