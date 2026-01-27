enum NotificationType {
  bidReceived,
  bidAccepted,
  bidRejected,
  taskCompleted,
  paymentReceived,
  paymentPending,
  newMessage,
  system,
  asapTask, // Added specific type for ASAP tasks
}

class AppNotification {
  final String id;
  final String title;
  final String message;
  final NotificationType type;
  final DateTime createdAt;
  final bool isRead;
  final bool isArchived;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.createdAt,
    this.isRead = false,
    this.isArchived = false,
    this.metadata,
  });

  AppNotification copyWith({
    String? id,
    String? title,
    String? message,
    NotificationType? type,
    DateTime? createdAt,
    bool? isRead,
    bool? isArchived,
    Map<String, dynamic>? metadata,
  }) {
    return AppNotification(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      isArchived: isArchived ?? this.isArchived,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.name, // Use .name to serialize
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isArchived': isArchived,
      'metadata': metadata,
    };
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    NotificationType parseType(String? typeStr) {
      if (typeStr == null) return NotificationType.system;
      
      // Handle snake_case from DB (e.g. 'asap_task') -> camelCase enum (asapTask)
      switch (typeStr) {
        case 'asap_task':
          return NotificationType.asapTask;
        case 'bid_received':
          return NotificationType.bidReceived;
        case 'bid_accepted':
          return NotificationType.bidAccepted;
        case 'bid_rejected':
          return NotificationType.bidRejected;
        case 'task_completed':
          return NotificationType.taskCompleted;
        case 'payment_received':
          return NotificationType.paymentReceived;
        case 'payment_pending':
          return NotificationType.paymentPending;
        case 'new_message':
          return NotificationType.newMessage;
        case 'system':
          return NotificationType.system;
        default:
          // Fallback: try to match enum name directly
          return NotificationType.values.firstWhere(
            (e) => e.name == typeStr,
            orElse: () => NotificationType.system,
          );
      }
    }

    return AppNotification(
      id: json['id'],
      title: json['title'],
      message: json['message'],
      type: parseType(json['type']),
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt']), // Handle both cases just to be safe
      isRead: json['is_read'] ?? json['isRead'] ?? false,
      isArchived: json['is_archived'] ?? json['isArchived'] ?? false,
      metadata: json['data'] ?? json['metadata'], // DB uses 'data', app might use 'metadata'
    );
  }

  @override
  String toString() {
    return 'AppNotification(id: $id, title: $title, type: $type, isRead: $isRead)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppNotification && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}