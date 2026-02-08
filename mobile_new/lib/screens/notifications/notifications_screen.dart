import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../config/theme.dart';
import '../../data_types/notification.dart';
import '../../managers/notifications_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: () => _markAllAsRead(ref),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showNotificationSettings(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Unread'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationsList(notifications, NotificationFilter.all),
          _buildNotificationsList(notifications, NotificationFilter.unread),
          _buildNotificationsList(notifications, NotificationFilter.archived),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    List<AppNotification> notifications,
    NotificationFilter filter,
  ) {
    final filteredNotifications = _filterNotifications(notifications, filter);

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(filter);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredNotifications.length,
      itemBuilder: (context, index) {
        final notification = filteredNotifications[index];
        return _buildNotificationCard(notification, ref);
      },
    );
  }

  Widget _buildNotificationCard(AppNotification notification, WidgetRef ref) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: notification.isRead ? AppTheme.grey400 : AppTheme.likeGreen,
        child: Icon(
          notification.isRead ? Icons.archive : Icons.mark_email_read,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        if (notification.isRead) {
          ref.read(notificationsProvider.notifier).archiveNotification(notification.id);
        } else {
          ref.read(notificationsProvider.notifier).markAsRead(notification.id);
        }
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: notification.isRead ? Colors.white : AppTheme.grey50,
        child: InkWell(
          onTap: () => _handleNotificationTap(notification, ref),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notification Icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: AppTheme.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: notification.isRead ? AppTheme.grey600 : AppTheme.navyDark,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppTheme.superLikeBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTheme.bodySmall.copyWith(
                          color: AppTheme.grey600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            timeago.format(notification.createdAt),
                            style: AppTheme.caption.copyWith(color: AppTheme.grey500),
                          ),
                          if (notification.metadata != null &&
                              notification.metadata!['priority'] == 'high')
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.nopeRed.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'HIGH',
                                style: AppTheme.caption.copyWith(
                                  color: AppTheme.nopeRed,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Button (if applicable)
                if (_hasAction(notification))
                  IconButton(
                    icon: Icon(
                      _getActionIcon(notification.type),
                      color: AppTheme.superLikeBlue,
                    ),
                    onPressed: () => _handleNotificationAction(notification, ref),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(NotificationFilter filter) {
    String message;
    String subMessage;
    IconData icon;

    switch (filter) {
      case NotificationFilter.all:
        message = 'No notifications yet';
        subMessage = 'You\'ll see updates about your tasks and bids here';
        icon = Icons.notifications_none;
        break;
      case NotificationFilter.unread:
        message = 'All caught up!';
        subMessage = 'You have no unread notifications';
        icon = Icons.check_circle;
        break;
      case NotificationFilter.archived:
        message = 'No archived notifications';
        subMessage = 'Archived notifications will appear here';
        icon = Icons.archive;
        break;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.grey400),
          const SizedBox(height: 16),
          Text(
            message,
            style: AppTheme.heading2.copyWith(color: AppTheme.grey600),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: AppTheme.bodyMedium.copyWith(color: AppTheme.grey500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification, WidgetRef ref) {
    // Mark as read if not already
    if (!notification.isRead) {
      ref.read(notificationsProvider.notifier).markAsRead(notification.id);
    }

    // Navigate based on notification type
    switch (notification.type) {
      case NotificationType.bidReceived:
      case NotificationType.bidAccepted:
      case NotificationType.bidRejected:
        // Navigate to task details
        if (notification.metadata != null && notification.metadata!['taskId'] != null) {
          // TODO: Navigate to task details screen
        }
        break;
      case NotificationType.taskCompleted:
      case NotificationType.paymentReceived:
        // Navigate to earnings/payments
        if (notification.metadata != null && notification.metadata!['taskId'] != null) {
          // TODO: Navigate to payment/earnings screen
        }
        break;
      case NotificationType.newMessage:
        // Navigate to chat
        if (notification.metadata != null && notification.metadata!['chatId'] != null) {
          // TODO: Navigate to chat screen
        }
        break;
      case NotificationType.asapTask:
        // Navigate to task details or re-show overlay
        if (notification.metadata != null && notification.metadata!['task_id'] != null) {
          // TODO: Navigate to task details
          // context.push('/tasks/${notification.metadata!['task_id']}');
        }
        break;
      default:
        break;
    }
  }

  void _handleNotificationAction(AppNotification notification, WidgetRef ref) {
    switch (notification.type) {
      case NotificationType.bidReceived:
        // Quick accept/reject actions could be shown here
        _showBidActions(notification, ref);
        break;
      case NotificationType.paymentPending:
        // Navigate to payment screen
        // TODO: Navigate to payment screen
        break;
      default:
        break;
    }
  }

  void _showBidActions(AppNotification notification, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: AppTheme.heading2,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Accept bid
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Accept'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.likeGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Reject bid
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.close),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.nopeRed),
                      foregroundColor: AppTheme.nopeRed,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead(WidgetRef ref) {
    ref.read(notificationsProvider.notifier).markAllAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const NotificationSettingsSheet(),
    );
  }

  List<AppNotification> _filterNotifications(
    List<AppNotification> notifications,
    NotificationFilter filter,
  ) {
    switch (filter) {
      case NotificationFilter.all:
        return notifications.where((n) => !n.isArchived).toList();
      case NotificationFilter.unread:
        return notifications.where((n) => !n.isRead && !n.isArchived).toList();
      case NotificationFilter.archived:
        return notifications.where((n) => n.isArchived).toList();
    }
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.bidReceived:
        return AppTheme.superLikeBlue;
      case NotificationType.bidAccepted:
        return AppTheme.likeGreen;
      case NotificationType.bidRejected:
        return AppTheme.nopeRed;
      case NotificationType.taskCompleted:
        return AppTheme.boostGold;
      case NotificationType.paymentReceived:
        return AppTheme.likeGreen;
      case NotificationType.paymentPending:
        return AppTheme.boostGold;
      case NotificationType.newMessage:
        return AppTheme.navyMedium;
      case NotificationType.asapTask:
        return AppTheme.nopeRed;
      case NotificationType.system:
        return AppTheme.grey600;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bidReceived:
        return Icons.work;
      case NotificationType.bidAccepted:
        return Icons.check_circle;
      case NotificationType.bidRejected:
        return Icons.cancel;
      case NotificationType.taskCompleted:
        return Icons.done_all;
      case NotificationType.paymentReceived:
        return Icons.currency_rupee;
      case NotificationType.paymentPending:
        return Icons.schedule;
      case NotificationType.newMessage:
        return Icons.message;
      case NotificationType.asapTask:
        return Icons.warning_rounded;
      case NotificationType.system:
        return Icons.info;
    }
  }

  IconData _getActionIcon(NotificationType type) {
    switch (type) {
      case NotificationType.bidReceived:
        return Icons.more_vert;
      case NotificationType.paymentPending:
        return Icons.payment;
      default:
        return Icons.arrow_forward;
    }
  }

  bool _hasAction(AppNotification notification) {
    return notification.type == NotificationType.bidReceived ||
           notification.type == NotificationType.paymentPending;
  }
}

enum NotificationFilter {
  all,
  unread,
  archived,
}

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() => _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState extends State<NotificationSettingsSheet> {
  bool _bidNotifications = true;
  bool _taskNotifications = true;
  bool _paymentNotifications = true;
  bool _messageNotifications = true;
  bool _marketingNotifications = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Notification Settings',
                style: AppTheme.heading2,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),

          _buildSettingItem(
            'Bid Notifications',
            'Get notified when someone bids on your tasks',
            _bidNotifications,
            (value) => setState(() => _bidNotifications = value),
          ),

          _buildSettingItem(
            'Task Updates',
            'Updates about task progress and completion',
            _taskNotifications,
            (value) => setState(() => _taskNotifications = value),
          ),

          _buildSettingItem(
            'Payment Notifications',
            'Payment received and pending payment alerts',
            _paymentNotifications,
            (value) => setState(() => _paymentNotifications = value),
          ),

          _buildSettingItem(
            'Messages',
            'New messages from workers and clients',
            _messageNotifications,
            (value) => setState(() => _messageNotifications = value),
          ),

          _buildSettingItem(
            'Marketing',
            'Tips, promotions, and platform updates',
            _marketingNotifications,
            (value) => setState(() => _marketingNotifications = value),
          ),

          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _saveSettings(context),
              child: const Text('Save Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.bodyMedium.copyWith(fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTheme.caption.copyWith(color: AppTheme.grey600),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.superLikeBlue,
          ),
        ],
      ),
    );
  }

  void _saveSettings(BuildContext context) {
    // TODO: Save settings to backend/local storage
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings saved successfully')),
    );
  }
}