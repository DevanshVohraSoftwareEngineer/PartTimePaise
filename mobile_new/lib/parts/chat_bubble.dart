import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data_types/message.dart';
import '../config/theme.dart';

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
  }) : super(key: key);

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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
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
                border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppTheme.grey200,
                child: Text(
                  message.senderName?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.navyMedium,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: isCurrentUser
                    ? const LinearGradient(
                        colors: [Color(0xFF833AB4), Color(0xFFC13584), Color(0xFFE1306C)],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      )
                    : null,
                color: isCurrentUser ? null : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF262626) : const Color(0xFFEFEFEF)),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isCurrentUser ? 20 : 4),
                  bottomRight: Radius.circular(isCurrentUser ? 4 : 20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isVideoCall) 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.videocam, 
                            size: 14, 
                            color: isCurrentUser ? Colors.white : AppTheme.superLikeBlue
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Video Call',
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.w900,
                              color: isCurrentUser ? Colors.white : AppTheme.superLikeBlue
                            ),
                          ),
                        ],
                      ),
                    ),
                  
                  // Message content
                  Text(
                    message.content,
                    style: AppTheme.bodyMedium.copyWith(
                      color: isCurrentUser ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                      height: 1.3,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) const SizedBox(width: 4),
        ],
      ),
    );
  }
}
