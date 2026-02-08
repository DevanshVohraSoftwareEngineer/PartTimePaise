import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';

class AgoraService {
  static const String appId = "YOUR_AGORA_APP_ID"; // User must provide this
  
  RtcEngine? _engine;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Request permissions
    await [Permission.microphone, Permission.camera].request();

    // 2. Create engine
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(const RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // 3. Enable video
    await _engine!.enableVideo();
    await _engine!.startPreview();

    _isInitialized = true;
    print('🎥 Agora Service Initialized');
  }

  RtcEngine get engine {
    if (_engine == null) throw Exception("Agora Engine not initialized");
    return _engine!;
  }

  Future<void> joinChannel(String channelName, int uid, String token) async {
    await initialize();
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: uid,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
      ),
    );
  }

  Future<void> leaveChannel() async {
    if (_engine != null) {
      await _engine!.leaveChannel();
      print('📤 Left Agora Channel');
    }
  }

  void dispose() {
    _engine?.release();
  }
}

final agoraServiceProvider = Provider((ref) {
  final service = AgoraService();
  ref.onDispose(() => service.dispose());
  return service;
});
