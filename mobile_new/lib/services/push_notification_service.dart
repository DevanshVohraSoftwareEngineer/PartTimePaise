
class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;

  PushNotificationService._internal();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    print('Push Notification Service stubbed (Native logic pending)');
    _isInitialized = true;
  }
}

