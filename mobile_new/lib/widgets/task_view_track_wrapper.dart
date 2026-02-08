import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class TaskViewTrackWrapper extends StatefulWidget {
  final String taskId;
  final Widget child;

  const TaskViewTrackWrapper({
    super.key,
    required this.taskId,
    required this.child,
  });

  @override
  State<TaskViewTrackWrapper> createState() => _TaskViewTrackWrapperState();
}

class _TaskViewTrackWrapperState extends State<TaskViewTrackWrapper> {
  @override
  void initState() {
    super.initState();
    _trackView();
  }

  void _trackView() async {
    try {
      await SupabaseService.instance.trackTaskView(widget.taskId);
    } catch (e) {
      // Silent error for analytics tracking
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
