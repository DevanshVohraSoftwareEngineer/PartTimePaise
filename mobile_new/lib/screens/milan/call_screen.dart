import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../config/theme.dart';

class CallScreen extends StatefulWidget {
  final String matchId;
  final bool isVoiceOnly;
  final String otherUserName;

  const CallScreen({
    Key? key,
    required this.matchId,
    this.isVoiceOnly = false,
    required this.otherUserName,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  int? _remoteUid;
  bool _localUserJoined = false;
  bool _isMuted = false;
  bool _isVideoOff = false;
  late RtcEngine _engine;

  // IMPORTANT: Replace with your actual Agora App ID
  // IMPORTANT: Replace with your actual Agora App ID
  static const String appId = "da0571340176413289945fc53725b8a6"; // Example Demo ID

  @override
  void initState() {
    super.initState();
    initAgora();
  }

  Future<void> initAgora() async {
    // Retrieve permissions
    await [Permission.microphone, Permission.camera].request();

    // Create the engine
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));

    _engine.registerEventHandler(
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
        onTokenPrivilegeWillExpire: (RtcConnection connection, String token) {
          debugPrint('[onTokenPrivilegeWillExpire] connection: ${connection.toJson()}, token: $token');
        },
      ),
    );

    if (widget.isVoiceOnly) {
      await _engine.disableVideo();
    } else {
      await _engine.enableVideo();
      await _engine.startPreview();
    }

    await _engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    
    // Join channel with matchId as channel name
    await _engine.joinChannel(
      token: "", // Use empty string for testing if token is not required in Agora Console
      channelId: widget.matchId.substring(0, 31), // Agora channel ID limit
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  @override
  void dispose() {
    _dispose();
    super.dispose();
  }

  Future<void> _dispose() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  void _onToggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
    _engine.muteLocalAudioStream(_isMuted);
  }

  void _onToggleVideo() {
    setState(() {
      _isVideoOff = !_isVideoOff;
    });
    _engine.muteLocalVideoStream(_isVideoOff);
  }

  void _onSwitchCamera() {
    _engine.switchCamera();
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
                              rtcEngine: _engine,
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
            child: Icon(
              _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.white : Colors.blueAccent,
              size: 20.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: _isMuted ? Colors.blueAccent : Colors.white,
            padding: const EdgeInsets.all(12.0),
          ),
          RawMaterialButton(
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              Icons.call_end,
              color: Colors.white,
              size: 35.0,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15.0),
          ),
          if (!widget.isVoiceOnly)
            RawMaterialButton(
              onPressed: _onToggleVideo,
              child: Icon(
                _isVideoOff ? Icons.videocam_off : Icons.videocam,
                color: _isVideoOff ? Colors.white : Colors.blueAccent,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: _isVideoOff ? Colors.blueAccent : Colors.white,
              padding: const EdgeInsets.all(12.0),
            ),
          if (!widget.isVoiceOnly)
            RawMaterialButton(
              onPressed: _onSwitchCamera,
              child: const Icon(
                Icons.switch_camera,
                color: Colors.blueAccent,
                size: 20.0,
              ),
              shape: const CircleBorder(),
              elevation: 2.0,
              fillColor: Colors.white,
              padding: const EdgeInsets.all(12.0),
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
                rtcEngine: _engine,
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
