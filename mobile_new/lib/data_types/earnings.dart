import 'package:equatable/equatable.dart';

class TaskEarnings extends Equatable {
  final String taskId;
  final String taskTitle;
  final double basePay;
  final double distanceBonus;
  final double surgeBonus;
  final double totalTaskEarnings;
  final DateTime completedAt;

  const TaskEarnings({
    required this.taskId,
    required this.taskTitle,
    required this.basePay,
    required this.distanceBonus,
    required this.surgeBonus,
    required this.totalTaskEarnings,
    required this.completedAt,
  });

  factory TaskEarnings.fromJson(Map<String, dynamic> json) {
    return TaskEarnings(
      taskId: json['task_id']?.toString() ?? '',
      taskTitle: json['task_title']?.toString() ?? '',
      basePay: (json['base_pay'] as num?)?.toDouble() ?? 0.0,
      distanceBonus: (json['distance_bonus'] as num?)?.toDouble() ?? 0.0,
      surgeBonus: (json['surge_bonus'] as num?)?.toDouble() ?? 0.0,
      totalTaskEarnings: (json['total_task_earnings'] as num?)?.toDouble() ?? 0.0,
      completedAt: DateTime.parse(json['completed_at'] ?? DateTime.now().toIso8601String()).toLocal(),
    );
  }

  @override
  List<Object?> get props => [taskId, totalTaskEarnings, completedAt];
}

class WorkerEarningsSummary extends Equatable {
  final List<TaskEarnings> taskEarnings;
  final double totalTaskEarnings;
  final double milestoneIncentives;
  final double grandTotal;

  const WorkerEarningsSummary({
    required this.taskEarnings,
    required this.totalTaskEarnings,
    required this.milestoneIncentives,
    required this.grandTotal,
  });

  @override
  List<Object?> get props => [totalTaskEarnings, milestoneIncentives, grandTotal];
}
