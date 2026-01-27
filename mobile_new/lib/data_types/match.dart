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
  final String? clientName;
  final String? clientAvatar;
  
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
    this.clientName,
    this.clientAvatar,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCount = 0,
  });

  factory TaskMatch.fromJson(Map<String, dynamic> json) {
    return TaskMatch(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      workerId: json['workerId'] as String,
      clientId: json['clientId'] as String,
      status: json['status'] as String,
      matchedAt: DateTime.parse(json['matchedAt'] as String),
      task: json['task'] != null ? Task.fromJson(json['task'] as Map<String, dynamic>) : null,
      workerName: json['workerName'] as String?,
      workerAvatar: json['workerAvatar'] as String?,
      clientName: json['clientName'] as String?,
      clientAvatar: json['clientAvatar'] as String?,
      lastMessage: json['lastMessage'] as String?,
      lastMessageAt: json['lastMessageAt'] != null 
          ? DateTime.parse(json['lastMessageAt'] as String)
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskId': taskId,
      'workerId': workerId,
      'clientId': clientId,
      'status': status,
      'matchedAt': matchedAt.toIso8601String(),
      'task': task?.toJson(),
      'workerName': workerName,
      'workerAvatar': workerAvatar,
      'clientName': clientName,
      'clientAvatar': clientAvatar,
      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt?.toIso8601String(),
      'unreadCount': unreadCount,
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
    String? clientName,
    String? clientAvatar,
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
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
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
        clientName,
        clientAvatar,
        lastMessage,
        lastMessageAt,
        unreadCount,
      ];
}
