import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/agora_service.dart';
import '../../config/theme.dart';

class VideoCallScreen extends ConsumerStatefulWidget {
  final String channelName;
  final String remoteUserName;

  const VideoCallScreen({
    super.key,
    required this.channelName,
    required this.remoteUserName,
  });

  @override
  ConsumerState<VideoCallScreen> createState() => _VideoCallScreenState();
}

class _VideoCallScreenState extends ConsumerState<VideoCallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _muted = false;
  bool _videoDisabled = false;

  @override
  void initState() {
    super.initState();
    _initAgora();
  }

  Future<void> _initAgora() async {
    final agora = ref.read(agoraServiceProvider);
    
    // Set up event handlers
    agora.engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint("local user ${connection.localUid} joined");
          setState(() {
            _localUserJoined = true;
          });
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint("remote user $remoteUid joined");
          setState(() {
            _remoteUid = remoteUid;
          });
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          debugPrint("remote user $remoteUid left channel");
          setState(() {
            _remoteUid = null;
          });
          Navigator.pop(context);
        },
      ),
    );

    // Join channel (using anonymous UID 0 and no token for dev testing)
    await agora.joinChannel(widget.channelName, 0, "");
  }

  @override
  void dispose() {
    ref.read(agoraServiceProvider).leaveChannel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: _remoteVideo(),
          ),
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 120,
              height: 180,
              child: Center(
                child: _localUserJoined
                    ? AgoraVideoView(
                        controller: VideoViewController(
                          rtcEngine: ref.read(agoraServiceProvider).engine,
                          canvas: const VideoCanvas(uid: 0),
                        ),
                      )
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          _buildToolbar(),
          _buildOverlayInfo(),
        ],
      ),
    );
  }

  Widget _buildOverlayInfo() {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            widget.remoteUserName,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          const Text(
            "SECURE CAMPUS CALL",
            style: TextStyle(color: AppTheme.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Positioned(
      bottom: 48,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _circleButton(
            _muted ? Icons.mic_off : Icons.mic,
            _muted ? Colors.white : Colors.white24,
            () {
              setState(() => _muted = !_muted);
              ref.read(agoraServiceProvider).engine.muteLocalAudioStream(_muted);
            },
          ),
          _circleButton(
            Icons.call_end,
            Colors.redAccent,
            () => Navigator.pop(context),
            isLarge: true,
          ),
          _circleButton(
            _videoDisabled ? Icons.videocam_off : Icons.videocam,
            _videoDisabled ? Colors.white : Colors.white24,
            () {
              setState(() => _videoDisabled = !_videoDisabled);
              ref.read(agoraServiceProvider).engine.muteLocalVideoStream(_videoDisabled);
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, Color color, VoidCallback onTap, {bool isLarge = false}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(isLarge ? 20 : 16),
        decoration: BoxDecoration(
          color: color.withOpacity(isLarge ? 1.0 : 0.2),
          shape: BoxShape.circle,
          border: isLarge ? null : Border.all(color: Colors.white24),
        ),
        child: Icon(icon, color: isLarge ? Colors.white : color, size: isLarge ? 32 : 24),
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: ref.read(agoraServiceProvider).engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.channelName),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppTheme.cyanAccent),
          const SizedBox(height: 24),
          Text(
            "Waitng for ${widget.remoteUserName}...",
            style: const TextStyle(color: Colors.white70, letterSpacing: 1),
          ),
        ],
      );
    }
  }
}
