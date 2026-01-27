import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import '../data_types/notification.dart';
import '../services/supabase_service.dart';

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, List<AppNotification>>(
  (ref) => NotificationsNotifier(ref.watch(supabaseServiceProvider)),
);

class NotificationsNotifier extends StateNotifier<List<AppNotification>> {
  final SupabaseService _supabaseService;
  StreamSubscription? _notificationsSubscription;

  NotificationsNotifier(this._supabaseService) : super([]) {
    _initializeRealtimeNotifications();
  }

  void _initializeRealtimeNotifications() {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;

    _notificationsSubscription = _supabaseService.getNotificationsStream().listen((data) {
      state = data.map((json) => AppNotification.fromJson(json)).toList();
    });
  }

  void _loadMockNotifications() {
    // Initial state or mock notifications if needed during development
  }

  NotificationType _parseNotificationType(String? type) {
    return NotificationType.values.firstWhere(
      (e) => e.name == type,
      orElse: () => NotificationType.system,
    );
  }

  @override
  void dispose() {
    _notificationsSubscription?.cancel();
    super.dispose();
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabaseService.markNotificationAsRead(notificationId);
      // Local state is updated automatically via stream
    } catch (e) {
      print('❌ Error marking notification as read: $e');
    }
  }

  Future<void> markAllAsRead() async {
    final userId = _supabaseService.currentUser?.id;
    if (userId == null) return;
    
    try {
      await _supabaseService.client
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId);
    } catch (e) {
      print('❌ Error marking all notifications as read: $e');
    }
  }

  Future<void> archiveNotification(String notificationId) async {
    try {
      await _supabaseService.archiveNotification(notificationId);
    } catch (e) {
      print('❌ Error archiving notification: $e');
    }
  }

  int get unreadCount => state.where((n) => !n.isRead && !n.isArchived).length;
}