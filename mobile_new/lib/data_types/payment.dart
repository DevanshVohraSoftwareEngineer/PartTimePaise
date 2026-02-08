import 'package:equatable/equatable.dart';

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

enum PaymentMethod {
  upi,
  card,
  netbanking,
  wallet,
}

enum PaymentType {
  instant, // Immediate transfer to worker
  onDemand, // Worker requests payment
}

class Payment extends Equatable {
  final String id;
  final String taskId;
  final String clientId;
  final String workerId;
  final double amount;
  final double platformFee;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final PaymentType paymentType;
  final PaymentStatus status;
  final String? transactionId;
  final String? upiId;
  final String? cardLast4;
  final String? bankName;
  final String? failureReason;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? updatedAt;

  const Payment({
    required this.id,
    required this.taskId,
    required this.clientId,
    required this.workerId,
    required this.amount,
    required this.platformFee,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentType,
    required this.status,
    this.transactionId,
    this.upiId,
    this.cardLast4,
    this.bankName,
    this.failureReason,
    required this.createdAt,
    this.completedAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? json['taskId']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? json['workerId']?.toString() ?? '',
      amount: _safeDoubleParse(json['amount']) ?? 0.0,
      platformFee: _safeDoubleParse(json['platform_fee'] ?? json['platformFee']) ?? 0.0,
      totalAmount: _safeDoubleParse(json['total_amount'] ?? json['totalAmount']) ?? 0.0,
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == (json['payment_method'] ?? json['paymentMethod']),
        orElse: () => PaymentMethod.upi,
      ),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == (json['payment_type'] ?? json['paymentType']),
        orElse: () => PaymentType.instant,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      transactionId: json['transaction_id'] ?? json['transactionId'],
      upiId: json['upi_id'] ?? json['upiId'],
      cardLast4: json['card_last4'] ?? json['cardLast4'],
      bankName: json['bank_name'] ?? json['bankName'],
      failureReason: json['failure_reason'] ?? json['failureReason'],
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt']),
      completedAt: (json['completed_at'] ?? json['completedAt']) != null
          ? _parseDateTime(json['completed_at'] ?? json['completedAt'])
          : null,
      updatedAt: (json['updated_at'] ?? json['updatedAt']) != null
          ? _parseDateTime(json['updated_at'] ?? json['updatedAt'])
          : null,
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date is String) return DateTime.parse(date).toLocal();
    if (date is DateTime) return date.toLocal();
    return DateTime.now();
  }

  static double? _safeDoubleParse(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'client_id': clientId,
      'worker_id': workerId,
      'amount': amount,
      'platform_fee': platformFee,
      'total_amount': totalAmount,
      'payment_method': paymentMethod.name,
      'payment_type': paymentType.name,
      'status': status.name,
      'transaction_id': transactionId,
      'upi_id': upiId,
      'card_last_4': cardLast4,
      'bank_name': bankName,
      'failure_reason': failureReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [id, taskId, clientId, workerId, amount, status, transactionId];
}

class PaymentDemand extends Equatable {
  final String id;
  final String taskId;
  final String workerId;
  final String clientId;
  final double requestedAmount;
  final String reason;
  final bool isAccepted;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const PaymentDemand({
    required this.id,
    required this.taskId,
    required this.workerId,
    required this.clientId,
    required this.requestedAmount,
    required this.reason,
    required this.isAccepted,
    required this.createdAt,
    this.respondedAt,
  });

  factory PaymentDemand.fromJson(Map<String, dynamic> json) {
    return PaymentDemand(
      id: json['id']?.toString() ?? '',
      taskId: json['task_id']?.toString() ?? json['taskId']?.toString() ?? '',
      workerId: json['worker_id']?.toString() ?? json['workerId']?.toString() ?? '',
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
      requestedAmount: (json['requested_amount'] ?? json['requestedAmount'])?.toDouble() ?? 0.0,
      reason: json['reason']?.toString() ?? '',
      isAccepted: json['is_accepted'] ?? json['isAccepted'] ?? false,
      createdAt: DateTime.parse(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      respondedAt: (json['responded_at'] ?? json['respondedAt']) != null
          ? DateTime.parse((json['responded_at'] ?? json['respondedAt']) as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, taskId, workerId, requestedAmount, isAccepted];
}