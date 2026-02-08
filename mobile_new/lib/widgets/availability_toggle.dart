import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/availability_service.dart';

class AvailabilityToggle extends ConsumerWidget {
  const AvailabilityToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(availabilityProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.grey,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.circle : Icons.circle_outlined,
            size: 12,
            color: isOnline ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isOnline ? 'ONLINE' : 'OFFLINE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isOnline ? Colors.green : Colors.grey,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: isOnline,
            onChanged: (_) => ref.read(availabilityProvider.notifier).toggleAvailability(),
            activeThumbColor: Colors.green,
            activeTrackColor: Colors.green.withOpacity(0.3),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: Colors.grey.withOpacity(0.3),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
