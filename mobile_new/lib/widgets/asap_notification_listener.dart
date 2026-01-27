
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../managers/notifications_provider.dart';
import '../managers/auth_provider.dart';
import '../managers/gig_requests_provider.dart';
import '../services/supabase_service.dart';
import '../widgets/asap_task_overlay.dart';
import '../parts/match_celebration_dialog.dart';
import '../data_types/gig_request.dart';
import '../utils/haptics.dart';

class ASAPNotificationListener extends ConsumerStatefulWidget {
  final Widget child;

  const ASAPNotificationListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ASAPNotificationListener> createState() => _ASAPNotificationListenerState();
}

class _ASAPNotificationListenerState extends ConsumerState<ASAPNotificationListener> {
  OverlayEntry? _currentOverlay;
  bool _isLockActive = false; // ✨ Magic: Prevent async race conditions
  final Map<String, DateTime> _rejectedRequests = {};
  RealtimeChannel? _callChannel;

  @override
  void dispose() {
    _removeOverlay();
    _callChannel?.unsubscribe();
    super.dispose();
  }

  void _handleGigRequests(List<GigRequest> requests) {
    debugPrint("ASAP_DEBUG: Received ${requests.length} total gig requests");
    
    // 1. Filter for PENDING requests only
    final pendingRequests = requests.where((r) => r.status == 'pending').toList();
    
    if (pendingRequests.isEmpty) {
      if (_currentOverlay != null) {
        debugPrint("ASAP_DEBUG: No pending requests, removing overlay");
        _removeOverlay();
      }
      return;
    }

    final currentUser = ref.read(currentUserProvider);
    debugPrint("ASAP_DEBUG: Current User Online Status: ${currentUser?.isOnline}");
    
    // ✨ Magic: Relaxed check for testing, but typically we want them to be online
    if (currentUser?.isOnline != true) {
      debugPrint("ASAP_DEBUG: User NOT online, ignoring requests");
      return;
    }

    // Strict singularity check: don't start a new flow if one is active or loading
    if (_currentOverlay != null || _isLockActive) {
      debugPrint("ASAP_DEBUG: Overlay already active or lock engaged");
      return;
    }

    // 2. Pick the freshest pending request that isn't rejected
    final request = pendingRequests.firstWhere(
      (r) => !_rejectedRequests.containsKey(r.id),
      orElse: () => pendingRequests.first, // Fallback if all are somehow markers
    );

    if (_rejectedRequests.containsKey(request.id)) {
       debugPrint("ASAP_DEBUG: Request ${request.id} was rejected already");
       return;
    }

    debugPrint("ASAP_DEBUG: Triggering overlay for task ${request.taskId}");
    _fetchTaskAndShowOverlay(request);
  }

  Future<void> _fetchTaskAndShowOverlay(GigRequest request) async {
    if (_isLockActive) return;
    
    setState(() => _isLockActive = true);
    
    try {
      final supabase = ref.read(supabaseServiceProvider);
      final taskData = await supabase.client
          .from('tasks')
          .select()
          .eq('id', request.taskId)
          .single();

      // UNIVERSAL ALARM: Both ASAP and Today tasks now use the Alarm UI for guaranteed allotment
      if (taskData['urgency'] == 'asap' || taskData['urgency'] == 'today') {
        _showASAPOverlay(
          requestId: request.id,
          taskId: request.taskId,
          title: taskData['title'],
          budget: taskData['budget'].toString(),
          expiresAt: request.expiresAt,
          pickupLat: taskData['pickup_lat']?.toDouble(),
          pickupLng: taskData['pickup_lng']?.toDouble(),
        );
      } else {
        setState(() => _isLockActive = false);
      }
    } catch (e) {
      print("Error fetching task for overlay: $e");
      setState(() => _isLockActive = false);
    }
  }

  void _showASAPOverlay({
    required String requestId,
    required String taskId,
    required String title,
    required String budget,
    required DateTime expiresAt,
    double? pickupLat,
    double? pickupLng,
  }) {
    if (_currentOverlay != null) return;

    _currentOverlay = OverlayEntry(
      builder: (context) => Positioned.fill(
        child: ASAPTaskOverlay(
          taskId: taskId,
          title: title,
          budget: budget,
          expiresAt: expiresAt,
          onAccept: () async {
            final supabaseService = ref.read(supabaseServiceProvider);
            final result = await supabaseService.client.rpc('accept_gig', params: {'request_id': requestId});
            final matchId = result as String?;
            
            _removeOverlay();
            
            if (mounted && matchId != null) {
              AppHaptics.heavy();
              context.go('/matches/$matchId/chat');
            }
          },
          onReject: () async {
            final provider = ref.read(gigRequestsProvider.notifier);
            await provider.updateStatus(requestId, 'rejected');
            _removeOverlay();
            _rejectedRequests[requestId] = DateTime.now();
          },
        ),
      ),
    );

    Overlay.of(context).insert(_currentOverlay!);
    // Lock remains active until overlay is cleared manually or by request change
  }

  void _removeOverlay() {
    _currentOverlay?.remove();
    _currentOverlay = null;
    _isLockActive = false; // Release lock
  }

  void _setupCallListener() {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    _callChannel?.unsubscribe();
    final supabase = ref.read(supabaseServiceProvider);
    
    _callChannel = supabase.client.channel('user_calls:${currentUser.id}');
    _callChannel!.onBroadcast(
      event: 'incoming_call',
      callback: (payload) {
        _showIncomingCallDialog(payload);
      },
    ).subscribe();
  }

  void _showIncomingCallDialog(Map<String, dynamic> payload) {
    if (!mounted) return;
    
    final String callerName = payload['callerName'] ?? 'Someone';
    final String? callerAvatar = payload['callerAvatar'];
    final bool isVoiceOnly = payload['isVoiceOnly'] ?? false;
    final String matchId = payload['matchId'];

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 40,
              backgroundImage: callerAvatar != null ? NetworkImage(callerAvatar) : null,
              child: callerAvatar == null ? const Icon(Icons.person, size: 40) : null,
            ),
            const SizedBox(height: 20),
            Text(
              callerName,
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              isVoiceOnly ? "Incoming Voice Call" : "Incoming Video Call",
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    child: const Icon(Icons.call_end, color: Colors.white, size: 30),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/call/$matchId', extra: {
                      'isVoiceOnly': isVoiceOnly,
                      'otherUserName': callerName,
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                    child: Icon(isVoiceOnly ? Icons.call : Icons.videocam, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<GigRequest>>(gigRequestsProvider, (previous, next) {
      _handleGigRequests(next);
    });

    ref.listen(currentUserProvider, (previous, next) {
      if (previous?.isOnline != true && next?.isOnline == true) {
         final requests = ref.read(gigRequestsProvider);
         _handleGigRequests(requests);
      }
      
      if (next != null && previous?.id != next.id) {
        _setupCallListener();
      }
    });

    // Initial setup if user already logged in
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(currentUserProvider) != null && _callChannel == null) {
        _setupCallListener();
      }
    });

    return widget.child;
  }
}
