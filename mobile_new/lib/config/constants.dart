class AppConstants {
  // API Configuration
  // Use 10.0.2.2 for Android Emulator (maps to host machine's localhost)
  // Use localhost for iOS Simulator or change to your actual IP for physical devices
  static const String baseUrl = 'http://10.0.2.2:5000/api/v1';
  static const String socketUrl = 'http://10.0.2.2:5000';
  
  // Animation Durations
  static const Duration swipeAnimationDuration = Duration(milliseconds: 300);
  static const Duration matchAnimationDuration = Duration(milliseconds: 1500);
  
  // Swipe Configuration
  static const double swipeThreshold = 0.3;
  static const double maxRotationAngle = 30.0; // degrees
  static const double swipeExitDistance = 1000.0; // pixels
  
  // Distance Configuration
  static const int maxDistanceKm = 50;
  
  // Pagination
  static const int tasksPerPage = 20;
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  
  // Task Categories
  static const List<String> taskCategories = [
    'Tutoring',
    'Delivery',
    'Content Creation',
    'Tech Support',
    'Event Help',
    'Moving',
    'Pet Care',
    'Other'
  ];
  
  // Task Status
  static const String taskStatusOpen = 'open';
  static const String taskStatusMatched = 'assigned';
  static const String taskStatusInProgress = 'in_progress';
  static const String taskStatusCompleted = 'completed';
  static const String taskStatusCancelled = 'cancelled';
  
  // Match Status
  static const String matchStatusPending = 'pending';
  static const String matchStatusAccepted = 'accepted';
  static const String matchStatusRejected = 'rejected';
  
  // User Roles
  static const String roleClient = 'client';
  static const String roleWorker = 'worker';
}
