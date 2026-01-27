import 'package:equatable/equatable.dart';
import 'task.dart';

class TaskMatch extends Equatable {
  final String id;
  final String taskId;
  final String workerId;
  final String clientId;
  final String status;
  final DateTime matchedAt;
  
  // Populated task and user info
  final Task? task;
  final String? workerName;
  final String? workerAvatar;
  final double? workerLat;
  final double? workerLng;
  final String? clientName;
  final String? clientAvatar;
  final double? clientLat;
  final double? clientLng;
  final String? clientIdCardUrl;
  final String? clientSelfieUrl;
  final String? clientVerificationStatus;
  final String? workerIdCardUrl;
  final String? workerSelfieUrl;
  final String? workerVerificationStatus;
  
  // Last message info
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const TaskMatch({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.clientId,
    required this.status,
    required this.matchedAt,
    this.task,
    this.workerName,
    this.workerAvatar,
    this.workerLat,
    this.workerLng,
    this.workerIdCardUrl,
    this.workerSelfieUrl,
    this.workerVerificationStatus,
    this.clientName,
    this.clientAvatar,
    this.clientLat,
    this.clientLng,
    this.clientIdCardUrl,
    this.clientSelfieUrl,
    this.clientVerificationStatus,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory TaskMatch.fromJson(Map<String, dynamic> json) {
    // Check if we have nested task OR flattened task fields from view
    Task? task;
    if (json['task'] != null) {
      task = Task.fromJson(json['task'] as Map<String, dynamic>);
    } else if (json['task_title'] != null) {
      // Reconstruct task info from flattened view fields
      task = Task(
        id: json['task_id']?.toString() ?? '',
        title: json['task_title']?.toString() ?? '',
        budget: (json['task_budget'] ?? 0).toDouble(),
        status: json['task_status']?.toString() ?? 'open',
        description: '', // Desc not needed for match list
        category: '',
        clientId: json['client_id']?.toString() ?? '',
        taskStatus: TaskStatus.open,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        clientName: json['client_name']?.toString() ?? '',
        clientAvatar: json['client_avatar']?.toString() ?? '',
        clientRating: 5.0,
      );
    }

    return TaskMatch(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? json['taskId']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? json['workerId']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'active',
      matchedAt: _parseDateTime(json['matched_at'] ?? json['matchedAt']),
      task: task,
      workerName: json['worker_name']?.toString() ?? json['workerName']?.toString(),
      workerAvatar: json['worker_avatar']?.toString() ?? json['workerAvatar']?.toString(),
      workerLat: (json['worker_lat'] ?? json['workerLat'])?.toDouble(),
      workerLng: (json['worker_lng'] ?? json['workerLng'])?.toDouble(),
      clientName: json['client_name']?.toString() ?? json['clientName']?.toString(),
      clientAvatar: json['client_avatar']?.toString() ?? json['clientAvatar']?.toString(),
      clientLat: (json['client_lat'] ?? json['clientLat'])?.toDouble(),
      clientLng: (json['client_lng'] ?? json['clientLng'])?.toDouble(),
      clientIdCardUrl: json['client_id_card_url']?.toString(),
      clientSelfieUrl: json['client_selfie_url']?.toString(),
      clientVerificationStatus: json['client_verification_status']?.toString(),
      workerIdCardUrl: json['worker_id_card_url']?.toString(),
      workerSelfieUrl: json['worker_selfie_url']?.toString(),
      workerVerificationStatus: json['worker_verification_status']?.toString(),
      lastMessage: json['last_message']?.toString() ?? json['lastMessage']?.toString(),
      lastMessageAt: (json['last_message_at'] ?? json['lastMessageAt']) != null 
          ? _parseDateTime(json['last_message_at'] ?? json['lastMessageAt'])
          : null,
      unreadCount: json['unread_count'] as int? ?? json['unreadCount'] as int? ?? 0,
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    } else if (date is DateTime) {
      return date;
    } else {
      return DateTime.now();
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'worker_id': workerId,
      'client_id': clientId,
      'status': status,
      'matched_at': matchedAt.toIso8601String(),
      'task': task?.toJson(),
      'worker_name': workerName,
      'worker_avatar': workerAvatar,
      'worker_lat': workerLat,
      'worker_lng': workerLng,
      'worker_id_card_url': workerIdCardUrl,
      'worker_selfie_url': workerSelfieUrl,
      'worker_verification_status': workerVerificationStatus,
      'client_name': clientName,
      'client_avatar': clientAvatar,
      'client_lat': clientLat,
      'client_lng': clientLng,
      'client_id_card_url': clientIdCardUrl,
      'client_selfie_url': clientSelfieUrl,
      'client_verification_status': clientVerificationStatus,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count': unreadCount,
    };
  }

  TaskMatch copyWith({
    String? id,
    String? taskId,
    String? workerId,
    String? clientId,
    String? status,
    DateTime? matchedAt,
    Task? task,
    String? workerName,
    String? workerAvatar,
    double? workerLat,
    double? workerLng,
    String? workerIdCardUrl,
    String? workerSelfieUrl,
    String? workerVerificationStatus,
    String? clientName,
    String? clientAvatar,
    double? clientLat,
    double? clientLng,
    String? clientIdCardUrl,
    String? clientSelfieUrl,
    String? clientVerificationStatus,
    String? lastMessage,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return TaskMatch(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      workerId: workerId ?? this.workerId,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      matchedAt: matchedAt ?? this.matchedAt,
      task: task ?? this.task,
      workerName: workerName ?? this.workerName,
      workerAvatar: workerAvatar ?? this.workerAvatar,
      workerLat: workerLat ?? this.workerLat,
      workerLng: workerLng ?? this.workerLng,
      workerIdCardUrl: workerIdCardUrl ?? this.workerIdCardUrl,
      workerSelfieUrl: workerSelfieUrl ?? this.workerSelfieUrl,
      workerVerificationStatus: workerVerificationStatus ?? this.workerVerificationStatus,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      clientLat: clientLat ?? this.clientLat,
      clientLng: clientLng ?? this.clientLng,
      clientIdCardUrl: clientIdCardUrl ?? this.clientIdCardUrl,
      clientSelfieUrl: clientSelfieUrl ?? this.clientSelfieUrl,
      clientVerificationStatus: clientVerificationStatus ?? this.clientVerificationStatus,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        taskId,
        workerId,
        clientId,
        status,
        matchedAt,
        task,
        workerName,
        workerAvatar,
        workerLat,
        workerLng,
        workerIdCardUrl,
        workerSelfieUrl,
        workerVerificationStatus,
        clientName,
        clientAvatar,
        clientLat,
        clientLng,
        clientIdCardUrl,
        clientSelfieUrl,
        clientVerificationStatus,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
