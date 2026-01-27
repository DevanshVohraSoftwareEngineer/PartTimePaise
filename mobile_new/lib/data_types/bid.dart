class Bid {
  final String id;
  final String taskId;
  final String workerId;
  final String workerName;
  final double amount;
  final String message;
  final String status; // 'pending', 'accepted', 'rejected'
  final String? workerFaceUrl;
  final String? workerIdCardUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Bid({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.workerName,
    required this.amount,
    required this.message,
    this.status = 'pending',
    this.workerFaceUrl,
    this.workerIdCardUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Bid.fromJson(Map<String, dynamic> json) {
    return Bid(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? json['taskId']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? json['workerId']?.toString() ?? '',
      workerName: json['worker_name']?.toString() ?? json['workerName']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      message: json['message']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      workerFaceUrl: json['worker_face_url']?.toString() ?? json['workerFaceUrl']?.toString(),
      workerIdCardUrl: json['worker_id_card_url']?.toString() ?? json['workerIdCardUrl']?.toString(),
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.parse((json['created_at'] ?? json['createdAt']) as String)
          : DateTime.now(),
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? DateTime.parse((json['updated_at'] ?? json['updatedAt']) as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'worker_id': workerId,
      'worker_name': workerName,
      'amount': amount,
      'message': message,
      'status': status,
      'worker_face_url': workerFaceUrl,
      'worker_id_card_url': workerIdCardUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Bid copyWith({
    String? id,
    String? taskId,
    String? workerId,
    String? workerName,
    double? amount,
    String? message,
    String? status,
    String? workerFaceUrl,
    String? workerIdCardUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Bid(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      amount: amount ?? this.amount,
      message: message ?? this.message,
      status: status ?? this.status,
      workerFaceUrl: workerFaceUrl ?? this.workerFaceUrl,
      workerIdCardUrl: workerIdCardUrl ?? this.workerIdCardUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bid && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}