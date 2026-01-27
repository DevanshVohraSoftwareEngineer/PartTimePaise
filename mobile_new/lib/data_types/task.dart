import 'package:equatable/equatable.dart';

enum TaskStatus {
  open,
  inProgress,
  completed,
  cancelled,
}

class Task extends Equatable {
  final String id;
  final String title;
  final String description;
  final String category;
  final double budget;
  final String? budgetType; // 'fixed' or 'hourly'
  final DateTime? deadline;
  final String? urgency; // 'low', 'medium', 'high'
  final String clientId;
  final String status;
  final TaskStatus taskStatus; // enum version
  final double? latitude;
  final double? longitude;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional client info (from join)
  final String? clientName;
  final String? clientAvatar;
  final String? clientFaceUrl;
  final String? clientIdCardUrl;
  final String? clientVerificationStatus;
  final double? clientRating;
  
  // Gig specific fields
  final String type; // 'general', 'delivery', 'cleaning', etc.
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final int? estimatedTimeMinutes;

  // Media & Stats
  final String? imageUrl;
  final List<String>? images;
  final int? bidsCount;
  final double? distanceMeters;

  // Anti-Scam OTPs
  final String? startOtp;
  final String? endOtp;
  
  // Expiration for time-sensitive tasks
  final DateTime? expiresAt;

  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.budget,
    this.budgetType,
    this.deadline,
    this.urgency,
    required this.clientId,
    required this.status,
    required this.taskStatus,
    this.latitude,
    this.longitude,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.clientName,
    this.clientAvatar,
    this.clientFaceUrl,
    this.clientIdCardUrl,
    this.clientVerificationStatus,
    this.clientRating,
    this.imageUrl,
    this.images,
    this.bidsCount,
    this.distanceMeters,
    this.type = 'general',
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    this.estimatedTimeMinutes,
    this.startOtp,
    this.endOtp,
    this.expiresAt,
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status']?.toString() ?? 'open';
    
    return Task(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      budget: _safeDoubleParse(json['budget']) ?? 0.0,
      budgetType: json['budget_type']?.toString() ?? json['budgetType']?.toString(),
      deadline: json['deadline'] != null ? _parseDateTime(json['deadline']) : null,
      urgency: json['urgency']?.toString(),
      clientId: json['client_id']?.toString() ?? json['clientId']?.toString() ?? '',
      status: statusStr,
      taskStatus: TaskStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => TaskStatus.open,
      ),
      latitude: _safeDoubleParse(json['latitude']),
      longitude: _safeDoubleParse(json['longitude']),
      location: json['location']?.toString(),
      createdAt: _parseDateTime(json['created_at'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: _parseDateTime(json['updated_at'] ?? json['updatedAt'] ?? DateTime.now().toIso8601String()),
      clientName: json['client_name']?.toString() ?? json['clientName']?.toString(),
      clientAvatar: json['client_avatar']?.toString() ?? json['clientAvatar']?.toString(),
      clientFaceUrl: json['client_face_url']?.toString() ?? json['clientFaceUrl']?.toString(),
      clientIdCardUrl: json['client_id_card_url']?.toString() ?? json['clientIdCardUrl']?.toString(),
      clientVerificationStatus: json['client_verification_status']?.toString() ?? json['clientVerificationStatus']?.toString(),
      clientRating: _safeDoubleParse(json['client_rating'] ?? json['clientRating']),
      imageUrl: json['image_url']?.toString() ?? json['imageUrl']?.toString(),
      images: json['images'] != null ? List<String>.from(json['images']) : null,
      bidsCount: _safeIntParse(json['bids_count'] ?? json['bidsCount']),
      distanceMeters: _safeDoubleParse(json['distance_km'] ?? json['distanceKm'] ?? json['distanceMeters']),
      type: json['type']?.toString() ?? 'general',
      pickupLat: _safeDoubleParse(json['pickup_lat']),
      pickupLng: _safeDoubleParse(json['pickup_lng']),
      dropoffLat: _safeDoubleParse(json['dropoff_lat']),
      dropoffLng: _safeDoubleParse(json['dropoff_lng']),
      estimatedTimeMinutes: _safeIntParse(json['estimated_time_minutes']),
      startOtp: json['start_otp']?.toString(),
      endOtp: json['end_otp']?.toString(),
      expiresAt: json['expires_at'] != null ? _parseDateTime(json['expires_at']) : null,
    );
  }

  static DateTime _parseDateTime(dynamic date) {
    if (date is String) {
      return DateTime.parse(date);
    } else if (date is DateTime) {
      return date;
    } else {
      return DateTime.now();
    }
  }

  static double? _safeDoubleParse(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _safeIntParse(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'budget': budget,
      'budget_type': budgetType,
      'deadline': deadline?.toIso8601String(),
      'urgency': urgency,
      'client_id': clientId,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'client_name': clientName,
      'client_avatar': clientAvatar,
      'client_face_url': clientFaceUrl,
      'client_id_card_url': clientIdCardUrl,
      'client_verification_status': clientVerificationStatus,
      'client_rating': clientRating,
      'image_url': imageUrl,
      'images': images,
      'bids_count': bidsCount,
      'distance_meters': distanceMeters,
      'type': type,
      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,
      'dropoff_lat': dropoffLat,
      'dropoff_lng': dropoffLng,
      'estimated_time_minutes': estimatedTimeMinutes,
      'start_otp': startOtp,
      'end_otp': endOtp,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    double? budget,
    String? budgetType,
    DateTime? deadline,
    String? urgency,
    String? clientId,
    String? status,
    TaskStatus? taskStatus,
    double? latitude,
    double? longitude,
    String? location,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientName,
    String? clientAvatar,
    String? clientFaceUrl,
    String? clientIdCardUrl,
    String? clientVerificationStatus,
    double? clientRating,
    String? imageUrl,
    List<String>? images,
    int? bidsCount,
    double? distanceMeters,
    String? type,
    double? pickupLat,
    double? pickupLng,
    double? dropoffLat,
    double? dropoffLng,
    int? estimatedTimeMinutes,
    String? startOtp,
    String? endOtp,
    DateTime? expiresAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      budget: budget ?? this.budget,
      budgetType: budgetType ?? this.budgetType,
      deadline: deadline ?? this.deadline,
      urgency: urgency ?? this.urgency,
      clientId: clientId ?? this.clientId,
      status: status ?? this.status,
      taskStatus: taskStatus ?? this.taskStatus,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientName: clientName ?? this.clientName,
      clientAvatar: clientAvatar ?? this.clientAvatar,
      clientFaceUrl: clientFaceUrl ?? this.clientFaceUrl,
      clientIdCardUrl: clientIdCardUrl ?? this.clientIdCardUrl,
      clientVerificationStatus: clientVerificationStatus ?? this.clientVerificationStatus,
      clientRating: clientRating ?? this.clientRating,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      bidsCount: bidsCount ?? this.bidsCount,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      type: type ?? this.type,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      startOtp: startOtp ?? this.startOtp,
      endOtp: endOtp ?? this.endOtp,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Task.empty()
      : id = '',
        title = '',
        description = '',
        category = '',
        budget = 0,
        budgetType = null,
        deadline = null,
        urgency = null,
        clientId = '',
        status = 'open',
        taskStatus = TaskStatus.open,
        latitude = null,
        longitude = null,
        location = null,
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        clientName = null,
        clientAvatar = null,
        clientFaceUrl = null,
        clientIdCardUrl = null,
        clientVerificationStatus = null,
        clientRating = null,
        imageUrl = null,
        images = null,
        bidsCount = null,
        distanceMeters = null,
        type = 'general',
        pickupLat = null,
        pickupLng = null,
        dropoffLat = null,
        dropoffLng = null,
        estimatedTimeMinutes = null,
        startOtp = null,
        endOtp = null,
        expiresAt = null;

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        budget,
        budgetType,
        deadline,
        urgency,
        clientId,
        status,
        taskStatus,
        latitude,
        longitude,
        location,
        createdAt,
        updatedAt,
        clientName,
        clientAvatar,
        clientFaceUrl,
        clientIdCardUrl,
        clientVerificationStatus,
        clientRating,
        imageUrl,
        images,
        bidsCount,
        distanceMeters,
        type,
        pickupLat,
        pickupLng,
        dropoffLat,
        dropoffLng,
        estimatedTimeMinutes,
        startOtp,
        endOtp,
        expiresAt,
      ];
}
