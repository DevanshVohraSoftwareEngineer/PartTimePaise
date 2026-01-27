import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../data_types/task_match.dart';
import '../data_types/message.dart';
import '../data_types/task.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

// Matches state
class MatchesState {
  final List<TaskMatch> matches;
  final List<Map<String, dynamic>> candidates; // New: Interested users
  final bool isLoading;
  final String? error;

  const MatchesState({
    this.matches = const [],
    this.candidates = const [],
    this.isLoading = false,
    this.error,
  });

  MatchesState copyWith({
    List<TaskMatch>? matches,
    List<Map<String, dynamic>>? candidates,
    bool? isLoading,
    String? error,
  }) {
    return MatchesState(
      matches: matches ?? this.matches,
      candidates: candidates ?? this.candidates,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MatchesNotifier extends StateNotifier<MatchesState> {
  final SupabaseService _supabaseService;

  MatchesNotifier(this._supabaseService) : super(const MatchesState()) {
    _initializeRealtimeListeners();
  }

  void _initializeRealtimeListeners() {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    // 1. Matches Stream
    _supabaseService.getMatchesStream().listen((data) async {
      await _fetchMatches(data);
    });

    // 2. Candidates Stream
    _supabaseService.getIncomingSwipesStream().listen((swipesData) async {
       await _fetchCandidates(swipesData, userId);
    });
  }

  Future<void> _fetchMatches(List<Map<String, dynamic>> data) async {
    final List<TaskMatch> hydratedMatches = [];
    
    for (var json in data) {
      final matchId = json['id'].toString();
      try {
        final enrichedData = await _supabaseService.client
          .from('enriched_matches')
          .select()
          .eq('id', matchId)
          .maybeSingle();
          
        if (enrichedData != null) {
          hydratedMatches.add(TaskMatch.fromJson(enrichedData));
        } else {
          // Fallback: Manually hydrate profile data if view fails
          final match = TaskMatch.fromJson(json);
          final otherUserId = _supabaseService.currentUser?.id == match.clientId 
              ? match.workerId 
              : match.clientId;
              
          final profile = await _supabaseService.client
              .from('profiles')
              .select('name, avatar_url, id_card_url, selfie_url, verification_status')
              .eq('id', otherUserId)
              .maybeSingle();
              
          if (profile != null) {
            hydratedMatches.add(match.copyWith(
              workerName: match.workerId == otherUserId ? profile['name'] : match.workerName,
              workerAvatar: match.workerId == otherUserId ? profile['avatar_url'] : match.workerAvatar,
              workerIdCardUrl: match.workerId == otherUserId ? profile['id_card_url'] : match.workerIdCardUrl,
              workerSelfieUrl: match.workerId == otherUserId ? profile['selfie_url'] : match.workerSelfieUrl,
              workerVerificationStatus: match.workerId == otherUserId ? profile['verification_status'] : match.workerVerificationStatus,
              clientName: match.clientId == otherUserId ? profile['name'] : match.clientName,
              clientAvatar: match.clientId == otherUserId ? profile['avatar_url'] : match.clientAvatar,
              clientIdCardUrl: match.clientId == otherUserId ? profile['id_card_url'] : match.clientIdCardUrl,
              clientSelfieUrl: match.clientId == otherUserId ? profile['selfie_url'] : match.clientSelfieUrl,
              clientVerificationStatus: match.clientId == otherUserId ? profile['verification_status'] : match.clientVerificationStatus,
            ));
          } else {
            hydratedMatches.add(match);
          }
        }
      } catch (e) {
        hydratedMatches.add(TaskMatch.fromJson(json));
      }
    }

    state = state.copyWith(
      matches: hydratedMatches,
      isLoading: false,
    );
  }

  Future<void> _fetchCandidates(List<Map<String, dynamic>> swipesData, String userId) async {
    final myTasksResponse = await _supabaseService.client
      .from('tasks')
      .select('id, title')
      .eq('client_id', userId);
      
    final myTaskIds = (myTasksResponse as List).map((t) => t['id'] as String).toSet();
    final relevantSwipes = swipesData.where((s) => myTaskIds.contains(s['task_id'])).toList();
    
    List<Map<String, dynamic>> enrichedCandidates = [];
    
    for (var swipe in relevantSwipes) {
      final profile = await _supabaseService.client
        .from('profiles')
        .select('name, avatar_url, rating')
        .eq('id', swipe['user_id'])
        .maybeSingle();

      final task = myTasksResponse.firstWhere((t) => t['id'] == swipe['task_id'], orElse: () => {});
      
      if (profile != null) {
        enrichedCandidates.add({
          'swipe_id': swipe['id'],
          'worker_id': swipe['user_id'],
          'task_id': swipe['task_id'],
          'task_title': task['title'] ?? 'Unknown Task',
          'worker_name': profile['name'],
          'worker_avatar': profile['avatar_url'],
          'worker_rating': profile['rating'],
          'created_at': swipe['created_at'],
        });
      }
    }
    
    state = state.copyWith(candidates: enrichedCandidates, isLoading: false);
  }

  Future<String?> acceptCandidate(String taskId, String workerId) async {
    try {
      // Optimistically find candidate data to create a local match object
      final candidate = state.candidates.firstWhere(
        (c) => c['worker_id'] == workerId && c['task_id'] == taskId,
        orElse: () => {},
      );

      final matchId = await _supabaseService.createMatch(taskId, workerId);
      
      if (matchId != null && candidate.isNotEmpty) {
        // Optimistically add to matches list if not already there via stream
        final optimisticMatch = TaskMatch(
          id: matchId,
          taskId: taskId,
          workerId: workerId,
          clientId: _supabaseService.currentUser?.id ?? '',
          status: 'active',
          matchedAt: DateTime.now(),
          workerName: candidate['worker_name'],
          workerAvatar: candidate['worker_avatar'],
          task: Task(
            id: taskId,
            title: candidate['task_title'] ?? 'Task',
            budget: (candidate['worker_rating'] ?? 0.0).toDouble(), // placeholder
            status: 'assigned',
            description: '',
            category: '',
            clientId: _supabaseService.currentUser?.id ?? '',
            taskStatus: TaskStatus.inProgress,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            clientName: '',
            clientAvatar: '',
          ),
        );
        
        state = state.copyWith(
          matches: [optimisticMatch, ...state.matches],
          candidates: state.candidates.where((c) => c['worker_id'] != workerId || c['task_id'] != taskId).toList(),
        );
      }
      
      return matchId;
    } catch (e) {
      print("Accept Candidate Error: $e");
      state = state.copyWith(error: e.toString());
      return null;
    }
  }

  Future<void> rejectCandidate(String taskId, String workerId) async {
    try {
      await _supabaseService.rejectCandidate(taskId, workerId);
      state = state.copyWith(
        candidates: state.candidates.where((c) => c['worker_id'] != workerId || c['task_id'] != taskId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadMatches() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    state = state.copyWith(isLoading: true);
    
    // Explicitly fetch matches
    final matchesData = await _supabaseService.client
        .from('matches')
        .select()
        .or('client_id.eq.$userId,worker_id.eq.$userId')
        .order('created_at', ascending: false);
    
    await _fetchMatches(List<Map<String, dynamic>>.from(matchesData));

    // Explicitly fetch candidates (Incoming Swipes)
    final swipesData = await _supabaseService.client
        .from('swipes')
        .select()
        .eq('direction', 'right')
        .order('created_at', ascending: false);

    await _fetchCandidates(List<Map<String, dynamic>>.from(swipesData), userId);
    
    state = state.copyWith(isLoading: false);
  }

  void addMatch(TaskMatch match) {
    state = state.copyWith(matches: [match, ...state.matches]);
  }
}

final matchesProvider = StateNotifierProvider<MatchesNotifier, MatchesState>((ref) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return MatchesNotifier(supabaseService);
});

// Chat state for a specific match
class ChatState {
  final String matchId;
  final List<Message> messages;
  final bool isLoading;
  final String? error;
  final bool isTyping;
  final bool isOtherUserPresent; // Snapchat style: indicator when other person is IN the chat
  final bool isOtherUserOnline;   // True if the user is online globally

  const ChatState({
    required this.matchId,
    this.messages = const [],
    this.isLoading = false,
    this.error,
    this.isTyping = false,
    this.isOtherUserPresent = false,
    this.isOtherUserOnline = false,
  });

  ChatState copyWith({
    List<Message>? messages,
    bool? isLoading,
    String? error,
    bool? isTyping,
    bool? isOtherUserPresent,
    bool? isOtherUserOnline,
  }) {
    return ChatState(
      matchId: matchId,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isTyping: isTyping ?? this.isTyping,
      isOtherUserPresent: isOtherUserPresent ?? this.isOtherUserPresent,
      isOtherUserOnline: isOtherUserOnline ?? this.isOtherUserOnline,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final String matchId;
  final SupabaseService _supabaseService;
  StreamSubscription<List<Map<String, dynamic>>>? _messagesSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _onlineStatusSubscription;
  RealtimeChannel? _typingChannel;
  RealtimeChannel? _presenceChannel;

  ChatNotifier(
    this.matchId,
    this._supabaseService,
  ) : super(ChatState(matchId: matchId)) {
    _init();
  }

  void _init() {
    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // Listen for real-time message updates
    _messagesSubscription = _supabaseService.getMessagesStream(matchId).listen((data) {
      final messages = data.map((json) => Message.fromJson(json)).toList();
      state = state.copyWith(messages: messages, isLoading: false);
    }, onError: (error) {
      state = state.copyWith(error: error.toString(), isLoading: false);
    });
    
    // Listen for global online status of the other user
    _setupOnlineStatusListener();

    // Listen for presence in this specific chat
    _setupPresenceListener();

    // Listen for typing indicators
    _typingChannel = _supabaseService.getTypingChannel(matchId);
    _typingChannel!.onBroadcast(
      event: 'typing',
      callback: (payload) {
        final userId = payload['userId'];
        final isTyping = payload['isTyping'] as bool;
        
        // If it's the other user, update state
        if (userId != _supabaseService.currentUser?.id) {
          state = state.copyWith(isTyping: isTyping);
        }
      },
    ).subscribe();
  }

  void _setupOnlineStatusListener() async {
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId == null) return;

    // Get match to find other user ID
    final matchesRes = await _supabaseService.client
      .from('matches')
      .select('client_id, worker_id')
      .eq('id', matchId)
      .maybeSingle();

    if (matchesRes == null) return;
    
    final String otherUserId = matchesRes['client_id'] == currentUserId 
        ? matchesRes['worker_id'] 
        : matchesRes['client_id'];

    // Stream the profile's is_online status
    _onlineStatusSubscription = _supabaseService.client
      .from('profiles')
      .stream(primaryKey: ['id'])
      .eq('id', otherUserId)
      .listen((data) {
        if (data.isNotEmpty) {
          final isOnline = data.first['is_online'] as bool? ?? false;
          state = state.copyWith(isOtherUserOnline: isOnline);
        }
      });
  }

  void _setupPresenceListener() {
    // Snapchat Style Chat Presence
    final currentUserId = _supabaseService.currentUser?.id;
    if (currentUserId != null) {
      _presenceChannel = _supabaseService.getChatPresenceChannel(matchId);
      _presenceChannel!.onPresenceSync((_) {
        final presenceList = _presenceChannel!.presenceState();
        bool otherPresent = false;
        
        // Handle as List<SinglePresenceState>
        for (var p in presenceList) {
           final pDyn = p as dynamic;
           // Attempt to access payload safely
           try {
             final payload = pDyn.payload as Map<String, dynamic>;
             if (payload['user_id'] != currentUserId) {
               otherPresent = true;
               break;
             }
           } catch (e) {
             print('Presence payload error: $e');
           }
        }
        
        state = state.copyWith(isOtherUserPresent: otherPresent);
      }).subscribe((status, [error]) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await _presenceChannel!.track({
            'user_id': currentUserId,
          });
        }
      });
    }
  }

  Future<void> sendMessage(String content, {String type = 'text'}) async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    // Optimistic UI update
    final optimisticMessage = Message(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      matchId: matchId,
      senderId: userId,
      senderName: 'Me', 
      content: content,
      timestamp: DateTime.now(),
      type: type,
    );
    
    final previousMessages = state.messages;
    state = state.copyWith(messages: [...previousMessages, optimisticMessage]);

    try {
      await _supabaseService.sendMessage(matchId, content, type: type); 
    } catch (e) {
      // Revert on failure
      state = state.copyWith(
        messages: previousMessages,
        error: 'Failed to send: $e',
      );
    }
  }

  void sendTypingIndicator(bool isTyping) {
    _supabaseService.setTypingStatus(matchId, isTyping);
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _onlineStatusSubscription?.cancel();
    _typingChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    super.dispose();
  }
}

final chatProvider = StateNotifierProvider.family<ChatNotifier, ChatState, String>((ref, matchId) {
  final supabaseService = ref.watch(supabaseServiceProvider);
  return ChatNotifier(matchId, supabaseService);
});
