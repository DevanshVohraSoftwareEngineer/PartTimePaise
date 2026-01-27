import '../data_types/task_match.dart';
import 'demo_tasks.dart';

class DemoMatches {
  static List<TaskMatch> getDemoMatches() {
    final now = DateTime.now();
    final tasks = DemoTasks.getDemoTasks();

    return [
      TaskMatch(
        id: 'match_1',
        taskId: '1',
        workerId: 'worker_1',
        clientId: 'demo_client_1',
        status: 'active',
        matchedAt: now.subtract(const Duration(hours: 2)),
        task: tasks[0], // Marketing Campaign
        workerName: 'Rohan Kumar',
        workerAvatar: null,
        clientName: 'Priya Sharma',
        clientAvatar: null,
        lastMessage: 'Sure! I can help you with the social media posts. When do you need them?',
        lastMessageAt: now.subtract(const Duration(minutes: 15)),
        unreadCount: 2,
      ),
      TaskMatch(
        id: 'match_2',
        taskId: '2',
        workerId: 'worker_2',
        clientId: 'demo_client_2',
        status: 'active',
        matchedAt: now.subtract(const Duration(hours: 5)),
        task: tasks[1], // Python Assignment
        workerName: 'Aarav Singh',
        workerAvatar: null,
        clientName: 'Rahul Verma',
        clientAvatar: null,
        lastMessage: 'Great! Can you share the assignment details?',
        lastMessageAt: now.subtract(const Duration(hours: 1)),
        unreadCount: 0,
      ),
      TaskMatch(
        id: 'match_3',
        taskId: '4',
        workerId: 'worker_3',
        clientId: 'demo_client_4',
        status: 'active',
        matchedAt: now.subtract(const Duration(days: 1)),
        task: tasks[3], // Event Photography
        workerName: 'Ishaan Patel',
        workerAvatar: null,
        clientName: 'Arjun Mehta',
        clientAvatar: null,
        lastMessage: 'Looking forward to the event! I will be there at 10 AM.',
        lastMessageAt: now.subtract(const Duration(hours: 3)),
        unreadCount: 1,
      ),
    ];
  }
}
