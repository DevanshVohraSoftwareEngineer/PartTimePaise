import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ASAPTaskAlertDialog extends StatelessWidget {
  final String taskId;
  final String title;
  final String budget;
  final DateTime expiresAt;

  const ASAPTaskAlertDialog({
    super.key,
    required this.taskId,
    required this.title,
    required this.budget,
    required this.expiresAt,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = expiresAt.difference(DateTime.now());
    final minutesLeft = remaining.inMinutes;

    return AlertDialog(
      backgroundColor: Colors.red.shade900,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.yellow, size: 32),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              '🚨 URGENT TASK NEARBY!',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Budget: ₹$budget',
            style: const TextStyle(
              color: Colors.greenAccent,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer, color: Colors.orange, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Expires in $minutesLeft minutes',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later', style: TextStyle(color: Colors.white70)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            context.go('/'); // Navigate to swipe feed where task will appear
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent,
            foregroundColor: Colors.black,
          ),
          child: const Text('View Now', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
