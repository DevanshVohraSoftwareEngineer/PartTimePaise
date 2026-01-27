import 'package:equatable/equatable.dart';

class ChatMessage extends Equatable {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final DateTime sentAt;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    required this.sentAt,
    this.isRead = false,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      matchId: json['matchId'] as String,
      senderId: json['senderId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
      isRead: json['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'matchId': matchId,
      'senderId': senderId,
      'content': content,
      'sentAt': sentAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  @override
  List<Object?> get props => [id, matchId, senderId, content, sentAt, isRead];
}
