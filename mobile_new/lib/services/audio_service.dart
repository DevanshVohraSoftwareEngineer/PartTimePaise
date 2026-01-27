import 'package:audioplayers/audioplayers.dart';
import 'dart:async';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _alarmPlayer = AudioPlayer();
  bool _isAlarmPlaying = false;

  /// Start playing the high-priority alarm sound in a loop
  Future<void> startAlarm() async {
    if (_isAlarmPlaying) return;
    
    try {
      _isAlarmPlaying = true;
      await _alarmPlayer.setReleaseMode(ReleaseMode.loop);
      // Using a generic system-like path for now, user should provide the asset
      await _alarmPlayer.play(AssetSource('audio/siren_alert.mp3'));
    } catch (e) {
      print('❌ AudioService: Error starting alarm: $e');
      _isAlarmPlaying = false;
    }
  }

  /// Stop the alarm immediately
  Future<void> stopAlarm() async {
    if (!_isAlarmPlaying) return;
    
    try {
      await _alarmPlayer.stop();
      _isAlarmPlaying = false;
    } catch (e) {
      print('❌ AudioService: Error stopping alarm: $e');
    }
  }

  /// Play a one-shot notification sound
  Future<void> playNotification() async {
    try {
      await _alarmPlayer.play(AssetSource('audio/notification_pop.mp3'), mode: PlayerMode.lowLatency);
    } catch (e) {
      print('❌ AudioService: Error playing notification: $e');
    }
  }

  void dispose() {
    _alarmPlayer.dispose();
  }
}

final audioService = AudioService();
