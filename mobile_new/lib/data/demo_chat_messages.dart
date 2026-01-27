import '../data_types/chat_message.dart';

class DemoChatMessages {
  static List<ChatMessage> getMessagesForMatch(String matchId) {
    final now = DateTime.now();

    if (matchId == 'match_1') {
      return [
        ChatMessage(
          id: 'msg_1',
          matchId: matchId,
          senderId: 'demo_client_1',
          content: 'Hi! I saw your profile and I think you would be perfect for this marketing campaign.',
          sentAt: now.subtract(const Duration(hours: 2)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_2',
          matchId: matchId,
          senderId: 'worker_1',
          content: 'Thank you! I would love to help. What kind of social media posts do you need?',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 50)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_3',
          matchId: matchId,
          senderId: 'demo_client_1',
          content: 'We need 10 Instagram posts and 5 Facebook posts for our new product launch.',
          sentAt: now.subtract(const Duration(hours: 1, minutes: 30)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_4',
          matchId: matchId,
          senderId: 'worker_1',
          content: 'Sure! I can help you with the social media posts. When do you need them?',
          sentAt: now.subtract(const Duration(minutes: 15)),
          isRead: false,
        ),
        ChatMessage(
          id: 'msg_5',
          matchId: matchId,
          senderId: 'demo_client_1',
          content: 'That would be great! I need them by Friday. Can you send me some examples of your previous work?',
          sentAt: now.subtract(const Duration(minutes: 5)),
          isRead: false,
        ),
      ];
    } else if (matchId == 'match_2') {
      return [
        ChatMessage(
          id: 'msg_6',
          matchId: matchId,
          senderId: 'demo_client_2',
          content: 'Hey! I need help with my Python data structures assignment.',
          sentAt: now.subtract(const Duration(hours: 5)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_7',
          matchId: matchId,
          senderId: 'worker_2',
          content: 'Hi! I would be happy to help. I have strong experience with Python and algorithms.',
          sentAt: now.subtract(const Duration(hours: 4, minutes: 30)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_8',
          matchId: matchId,
          senderId: 'demo_client_2',
          content: 'Perfect! The assignment covers binary trees and graph traversal.',
          sentAt: now.subtract(const Duration(hours: 4)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_9',
          matchId: matchId,
          senderId: 'worker_2',
          content: 'Great! Can you share the assignment details?',
          sentAt: now.subtract(const Duration(hours: 1)),
          isRead: true,
        ),
      ];
    } else if (matchId == 'match_3') {
      return [
        ChatMessage(
          id: 'msg_10',
          matchId: matchId,
          senderId: 'demo_client_4',
          content: 'Hi! Are you available for event photography next weekend?',
          sentAt: now.subtract(const Duration(days: 1)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_11',
          matchId: matchId,
          senderId: 'worker_3',
          content: 'Yes! I have experience with college events. What is the event about?',
          sentAt: now.subtract(const Duration(hours: 20)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_12',
          matchId: matchId,
          senderId: 'demo_client_4',
          content: 'It is our annual college fest - music, dance, and drama performances.',
          sentAt: now.subtract(const Duration(hours: 18)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_13',
          matchId: matchId,
          senderId: 'worker_3',
          content: 'Sounds exciting! I will bring my DSLR and backup equipment.',
          sentAt: now.subtract(const Duration(hours: 15)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_14',
          matchId: matchId,
          senderId: 'demo_client_4',
          content: 'Perfect! The event starts at 10 AM on Saturday.',
          sentAt: now.subtract(const Duration(hours: 10)),
          isRead: true,
        ),
        ChatMessage(
          id: 'msg_15',
          matchId: matchId,
          senderId: 'worker_3',
          content: 'Looking forward to the event! I will be there at 10 AM.',
          sentAt: now.subtract(const Duration(hours: 3)),
          isRead: false,
        ),
      ];
    }

    return [];
  }
}
