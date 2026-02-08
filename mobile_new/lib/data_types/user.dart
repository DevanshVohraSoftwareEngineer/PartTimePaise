import 'package:equatable/equatable.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String role; // 'client' or 'worker'
  final String? avatarUrl;
  final String? bio;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? phone;
  final double rating;
  final bool verified;
  final double walletBalance;
  final String? college;
  final int completedTasks;
  final DateTime createdAt;
  final bool isOnline;
  final int serviceRadius; // in meters
  final DateTime? lastSeen;
  final double? currentLat;
  final double? currentLng;
  final String? idCardUrl;
  final String? selfieUrl;
  final String? verificationStatus;

  const User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.bio,
    this.latitude,
    this.longitude,
    this.city,
    this.phone,
    this.rating = 0.0,
    this.verified = false,
    this.walletBalance = 0.0,
    this.college,
    this.completedTasks = 0,
    required this.createdAt,
    this.isOnline = false,
    this.serviceRadius = 5000,
    this.lastSeen,
    this.currentLat,
    this.currentLng,
    this.idCardUrl,
    this.selfieUrl,
    this.verificationStatus,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    try {
      // Defensive parsing with fallbacks
      final id = json['id']?.toString() ?? '';
      final email = json['email']?.toString() ?? '';
      final name = json['name']?.toString() ?? json['displayName']?.toString() ?? 'User';
      final role = json['role']?.toString() ?? 'worker';

      // Handle different avatar URL field names
      final avatarUrl = json['avatarUrl']?.toString() ??
                       json['profileImageUrl']?.toString() ??
                       json['photoURL']?.toString() ??
                       json['profilePicture']?.toString();

      // Safe numeric parsing
      final latitude = _safeDoubleParse(json['latitude']);
      final longitude = _safeDoubleParse(json['longitude']);
      final rating = _safeDoubleParse(json['rating']) ?? 0.0;
      final walletBalance = _safeDoubleParse(json['wallet_balance'] ?? json['walletBalance']) ?? 0.0;
      final completedTasks = _safeIntParse(json['completed_tasks'] ?? json['completedTasks']) ?? 0;
      final serviceRadius = _safeIntParse(json['service_radius_meters'] ?? json['serviceRadius']) ?? 5000;
      final currentLat = _safeDoubleParse(json['current_lat'] ?? json['currentLat']);
      final currentLng = _safeDoubleParse(json['current_lng'] ?? json['currentLng']);

      // Safe boolean parsing
      final verified = json['verified'] == true;
      final isOnline = json['is_online'] == true || json['isOnline'] == true;

      // Safe date parsing
      DateTime createdAt;
      try {
        if (json['createdAt'] is String) {
          createdAt = DateTime.parse(json['createdAt']).toLocal();
        } else if (json['created_at'] is String) {
          createdAt = DateTime.parse(json['created_at']).toLocal();
        } else {
          createdAt = DateTime.now();
        }
      } catch (e) {
        createdAt = DateTime.now();
      }

      DateTime? lastSeen;
      if (json['last_seen'] != null) {
        try {
           lastSeen = DateTime.parse(json['last_seen']).toLocal();
        } catch (_) {}
      }

      return User(
        id: id,
        email: email,
        name: name,
        role: role,
        avatarUrl: avatarUrl,
        bio: json['bio']?.toString(),
        latitude: latitude,
        longitude: longitude,
        city: json['city']?.toString() ?? json['location']?.toString(),
        phone: json['phone']?.toString(),
        rating: rating,
        verified: verified,
        walletBalance: walletBalance,
        college: json['college']?.toString(),
        completedTasks: completedTasks,
        createdAt: createdAt,
        isOnline: isOnline,
        serviceRadius: serviceRadius,
        lastSeen: lastSeen,
        currentLat: currentLat,
        currentLng: currentLng,
        idCardUrl: json['id_card_url']?.toString() ?? json['idCardUrl']?.toString(),
        selfieUrl: json['selfie_url']?.toString() ?? json['selfieUrl']?.toString(),
        verificationStatus: json['verification_status']?.toString() ?? json['verificationStatus']?.toString(),
      );
    } catch (e) {
      // Return a minimal user if parsing fails
      return User(
        id: json['id']?.toString() ?? 'unknown',
        email: json['email']?.toString() ?? 'unknown@example.com',
        name: json['name']?.toString() ?? json['displayName']?.toString() ?? 'User',
        role: json['role']?.toString() ?? 'worker',
        createdAt: DateTime.now(),
      );
    }
  }

  static double? _safeDoubleParse(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static int? _safeIntParse(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role,
      'avatarUrl': avatarUrl,
      'bio': bio,
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'phone': phone,
      'rating': rating,
      'verified': verified,
      'walletBalance': walletBalance,
      'college': college,
      'completedTasks': completedTasks,
      'createdAt': createdAt.toIso8601String(),
      'is_online': isOnline,
      'service_radius_meters': serviceRadius,
      'last_seen': lastSeen?.toIso8601String(),
      'current_lat': currentLat,
      'current_lng': currentLng,
      'id_card_url': idCardUrl,
      'selfie_url': selfieUrl,
      'verification_status': verificationStatus,
    };
  }

  User copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    String? avatarUrl,
    String? bio,
    double? latitude,
    double? longitude,
    String? city,
    String? phone,
    double? rating,
    bool? verified,
    double? walletBalance,
    String? college,
    int? completedTasks,
    DateTime? createdAt,
    bool? isOnline,
    int? serviceRadius,
    DateTime? lastSeen,
    double? currentLat,
    double? currentLng,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      phone: phone ?? this.phone,
      rating: rating ?? this.rating,
      verified: verified ?? this.verified,
      walletBalance: walletBalance ?? this.walletBalance,
      college: college ?? this.college,
      completedTasks: completedTasks ?? this.completedTasks,
      createdAt: createdAt ?? this.createdAt,
      isOnline: isOnline ?? this.isOnline,
      serviceRadius: serviceRadius ?? this.serviceRadius,
      lastSeen: lastSeen ?? this.lastSeen,
      currentLat: currentLat ?? this.currentLat,
      currentLng: currentLng ?? this.currentLng,
      idCardUrl: idCardUrl ?? idCardUrl,
      selfieUrl: selfieUrl ?? selfieUrl,
      verificationStatus: verificationStatus ?? verificationStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        role,
        avatarUrl,
        bio,
        latitude,
        longitude,
        city,
        phone,
        rating,
        verified,
        walletBalance,
        college,
        completedTasks,
        createdAt,
        isOnline,
        serviceRadius,
        lastSeen,
        currentLat,
        currentLng,
        idCardUrl,
        selfieUrl,
        verificationStatus,
      ];
}
