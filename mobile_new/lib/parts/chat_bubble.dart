import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data_types/message.dart';
import '../config/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../helpers/content_filter.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    if (message.type == 'system') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 40),
        child: Center(
          child: Text(
            message.content.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.grey400,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
        ),
      );
    }

    final bool isVideoCall = message.type == 'video_call';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            // Other user avatar (Small, sleek)
            Container(
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.grey200,
                backgroundImage: (message.senderAvatar != null && message.senderAvatar!.isNotEmpty) 
                  ? CachedNetworkImageProvider(message.senderAvatar!) 
                  : null,
                child: (message.senderAvatar == null || message.senderAvatar!.isEmpty) ? Text(
                  message.senderName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.navyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ) : null,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: isCurrentUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isCurrentUser
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isCurrentUser ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(22),
                      topRight: const Radius.circular(22),
                      bottomLeft: Radius.circular(isCurrentUser ? 22 : 4),
                      bottomRight: Radius.circular(isCurrentUser ? 4 : 22),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isCurrentUser ? 0.2 : 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.type == 'image')
                         ClipRRect(
                           borderRadius: BorderRadius.circular(12),
                           child: Image.network(message.content, fit: BoxFit.cover),
                         )
                      else if (message.type == 'video')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.video_library,
                                size: 16,
                                color: isCurrentUser ? Colors.white : AppTheme.electricMedium,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Video Message",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (message.type == 'voice')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic,
                                size: 16,
                                color: isCurrentUser ? Colors.white : AppTheme.electricMedium,
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Voice Message",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (isVideoCall) 
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.videocam,
                                size: 16,
                                color: isCurrentUser ? Colors.white : AppTheme.likeGreen,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Video Call",
                                style: TextStyle(
                                  color: isCurrentUser ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          ContentFilter.filter(message.content),
                          style: TextStyle(
                            color: isCurrentUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                            fontSize: 15,
                            height: 1.3,
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat('hh:mm a').format(message.timestamp),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.withOpacity(0.7),
                        ),
                      ),
                      if (isCurrentUser) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.read ? Icons.done_all : (message.id.startsWith('temp-') ? Icons.access_time_rounded : Icons.done_all),
                          size: 13,
                          color: message.read ? const Color(0xFF0095F6) : (message.id.startsWith('temp-') ? Colors.grey[400] : Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
