import 'package:equatable/equatable.dart';

class Message extends Equatable {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool read;
  
  // Sender info
  final String? senderName;
  final String? senderAvatar;
  final String type; // e.g., 'text', 'system', 'video_call'

  const Message({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.read = false,
    this.senderName,
    this.senderAvatar,
    this.type = 'text',
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id']?.toString() ?? '',
      matchId: json['match_id']?.toString() ?? json['matchId']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? json['senderId']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      timestamp: DateTime.parse(json['created_at'] ?? json['timestamp'] ?? DateTime.now().toIso8601String()),
      read: json['read'] as bool? ?? false,
      senderName: json['sender_name']?.toString() ?? json['senderName']?.toString(),
      senderAvatar: json['sender_avatar']?.toString() ?? json['senderAvatar']?.toString(),
      type: json['type']?.toString() ?? 'text',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'created_at': timestamp.toIso8601String(),
      'read': read,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'type': type,
    };
  }

  Message copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? content,
    DateTime? timestamp,
    bool? read,
    String? senderName,
    String? senderAvatar,
  }) {
    return Message(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      type: type ?? this.type,
    );
  }

  @override
  List<Object?> get props => [
        id,
        matchId,
        senderId,
        content,
        timestamp,
        read,
        senderName,
        senderAvatar,
        type,
      ];
}
