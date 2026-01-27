class GigRequest {
  final String id;
  final String taskId;
  final String workerId;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  GigRequest({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory GigRequest.fromJson(Map<String, dynamic> json) {
    return GigRequest(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? '') ?? DateTime.now().add(const Duration(minutes: 5)),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'worker_id': workerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
