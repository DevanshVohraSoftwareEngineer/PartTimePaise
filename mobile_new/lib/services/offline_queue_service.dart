import 'dart:async';
import 'dart:collection';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ========================================
// PHASE 7: OFFLINE QUEUE SERVICE 🛡️
// ========================================

/// Zomato-style offline queue for failure recovery
/// Queues critical actions when network is unavailable
/// Retries with exponential backoff when connection is restored
class OfflineQueueService {
  static final OfflineQueueService instance = OfflineQueueService._internal();
  OfflineQueueService._internal();

  final Queue<QueuedAction> _queue = Queue<QueuedAction>();
  Timer? _processingTimer;
  bool _isProcessing = false;

  static const String _storageKey = 'offline_queue';
  static const int _maxRetries = 5;

  /// Initialize and load persisted queue
  Future<void> initialize() async {
    await _loadQueue();
    _startProcessing();
  }

  /// Queue an action for later execution
  Future<void> queueAction({
    required String action,
    required Map<String, dynamic> data,
    int priority = 0,
  }) async {
    final queuedAction = QueuedAction(
      action: action,
      data: data,
      priority: priority,
      timestamp: DateTime.now(),
      retryCount: 0,
    );

    _queue.add(queuedAction);
    await _persistQueue();

    print('📦 Queued action: $action (queue size: ${_queue.length})');
  }

  /// Start processing queue with exponential backoff
  void _startProcessing() {
    _processingTimer?.cancel();
    _processingTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!_isProcessing && _queue.isNotEmpty) {
        await _processQueue();
      }
    });
  }

  /// Process queued actions
  Future<void> _processQueue() async {
    if (_queue.isEmpty) return;

    _isProcessing = true;

    while (_queue.isNotEmpty) {
      final action = _queue.first;

      try {
        // Execute the action
        await _executeAction(action);

        // Success - remove from queue
        _queue.removeFirst();
        await _persistQueue();

        print('✅ Processed: ${action.action}');
      } catch (e) {
        print('❌ Failed: ${action.action} - $e');

        // Check if retryable
        if (_isRetryable(e) && action.retryCount < _maxRetries) {
          // Update retry count and move to back of queue
          _queue.removeFirst();
          action.retryCount++;
          _queue.add(action);
          await _persistQueue();

          // Exponential backoff
          final backoffSeconds = (2 << action.retryCount) * 5;
          await Future.delayed(Duration(seconds: backoffSeconds));
        } else {
          // Non-retryable or max retries reached - discard
          _queue.removeFirst();
          await _persistQueue();
          print('🗑️ Discarded: ${action.action}');
        }
      }
    }

    _isProcessing = false;
  }

  /// Execute a queued action
  Future<void> _executeAction(QueuedAction action) async {
    // Implement action execution based on action type
    switch (action.action) {
      case 'send_message':
        // await _sendMessage(action.data);
        break;
      case 'accept_gig':
        // await _acceptGig(action.data);
        break;
      case 'update_location':
        // await _updateLocation(action.data);
        break;
      default:
        throw Exception('Unknown action: ${action.action}');
    }
  }

  /// Check if error is retryable
  bool _isRetryable(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('network') ||
        errorString.contains('timeout') ||
        errorString.contains('connection');
  }

  /// Persist queue to local storage
  Future<void> _persistQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueJson = _queue.map((a) => a.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(queueJson));
  }

  /// Load queue from local storage
  Future<void> _loadQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueString = prefs.getString(_storageKey);

    if (queueString != null) {
      final queueJson = jsonDecode(queueString) as List;
      _queue.addAll(queueJson.map((j) => QueuedAction.fromJson(j)));
      print('📦 Loaded ${_queue.length} queued actions');
    }
  }

  /// Clear the queue
  Future<void> clearQueue() async {
    _queue.clear();
    await _persistQueue();
  }

  /// Get queue size
  int get queueSize => _queue.length;
}

/// Represents a queued action
class QueuedAction {
  final String action;
  final Map<String, dynamic> data;
  final int priority;
  final DateTime timestamp;
  int retryCount;

  QueuedAction({
    required this.action,
    required this.data,
    required this.priority,
    required this.timestamp,
    required this.retryCount,
  });

  Map<String, dynamic> toJson() => {
        'action': action,
        'data': data,
        'priority': priority,
        'timestamp': timestamp.toIso8601String(),
        'retryCount': retryCount,
      };

  factory QueuedAction.fromJson(Map<String, dynamic> json) => QueuedAction(
        action: json['action'],
        data: json['data'],
        priority: json['priority'],
        timestamp: DateTime.parse(json['timestamp']),
        retryCount: json['retryCount'],
      );
}
