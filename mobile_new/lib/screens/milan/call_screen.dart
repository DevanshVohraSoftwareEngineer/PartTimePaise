import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/agora_service.dart';

class CallScreen extends ConsumerStatefulWidget {
  final String matchId;
  final bool isVoiceOnly;
  final String otherUserName;

  const CallScreen({
    super.key,
    required this.matchId,
    this.isVoiceOnly = false,
    required this.otherUserName,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
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

    if (widget.isVoiceOnly) {
      await agora.engine.disableVideo();
    } else {
      await agora.engine.enableVideo();
      await agora.engine.startPreview();
    }

    // Join channel (using anonymous UID 0 and no token for dev testing)
    await agora.joinChannel(widget.matchId, 0, "");
  }

  @override
  void dispose() {
    ref.read(agoraServiceProvider).leaveChannel();
    super.dispose();
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    ref.read(agoraServiceProvider).engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    ref.read(agoraServiceProvider).engine.muteLocalVideoStream(_isVideoOff);
  }

  void _onSwitchCamera() {
    ref.read(agoraServiceProvider).engine.switchCamera();
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
            child: Container(
              width: 100,
              height: 150,
              margin: const EdgeInsets.only(top: 50, left: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[900],
              ),
              child: Center(
                child: _localUserJoined
                    ? (widget.isVoiceOnly || _isVideoOff
                        ? const Icon(Icons.person, size: 50, color: Colors.white)
                        : AgoraVideoView(
                            controller: VideoViewController(
                              rtcEngine: ref.read(agoraServiceProvider).engine,
                              canvas: const VideoCanvas(uid: 0),
                            ),
                          ))
                    : const CircularProgressIndicator(),
              ),
            ),
          ),
          _buildToolbar(),
          _buildUserInfo(),
        ],
      ),
    );
  }

  Widget _buildUserInfo() {
    return Positioned(
      top: 60,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            widget.otherUserName,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Calling...",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          RawMaterialButton(
            onPressed: _onToggleMute,
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _isMuted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
            child: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
          ),
          if (!widget.isVoiceOnly)
            RawMaterialButton(
              onPressed: _onToggleVideo,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _isVideoOff ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: Icon(
                _isVideoOff ? Icons.videocam_off : Icons.videocam,
                color: _isVideoOff ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
            ),
          if (!widget.isVoiceOnly)
            RawMaterialButton(
              onPressed: _onSwitchCamera,
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
            ),
        ],
      ),
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null) {
      return widget.isVoiceOnly
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircleAvatar(
                  radius: 60,
                  child: Icon(Icons.person, size: 60),
                ),
                const SizedBox(height: 20),
                Text(
                  widget.otherUserName,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            )
          : AgoraVideoView(
              controller: VideoViewController.remote(
                rtcEngine: ref.read(agoraServiceProvider).engine,
                canvas: VideoCanvas(uid: _remoteUid),
                connection: RtcConnection(channelId: widget.matchId.substring(0, 31)),
              ),
            );
    } else {
      return Text(
        widget.isVoiceOnly ? 'Waiting for worker...' : 'Waiting for worker to join...',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white),
      );
    }
  }
}
