import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AgoraCallService {
  static const String appId = '3438fb4f909e4753b9f88291f2b22929';
  RtcEngine? _engine;
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    // Request permissions first and wait for result
    final statuses = await [Permission.microphone, Permission.camera].request();

    final micGranted = statuses[Permission.microphone]?.isGranted ?? false;
    final camGranted = statuses[Permission.camera]?.isGranted ?? false;

    debugPrint('Mic permission: $micGranted | Camera permission: $camGranted');

    if (!micGranted) throw Exception('Microphone permission denied');

    _engine = createAgoraRtcEngine();

    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));

    // Wait for engine to be fully ready — critical fix for -3 error
    await Future.delayed(const Duration(milliseconds: 500));

    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );

    debugPrint('Agora engine initialized successfully');
  }

  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String callType,
  }) async {
    final callerId = _supabase.auth.currentUser!.id;
    final channelName =
        'ch_${callerId.substring(0, 6)}_${receiverId.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

    debugPrint('Initiating $callType call on channel: $channelName');

    return await _supabase
        .from('calls')
        .insert({
          'caller_id': callerId,
          'receiver_id': receiverId,
          'channel_name': channelName,
          'call_type': callType,
          'status': 'ringing',
        })
        .select()
        .single();
  }

  Future<void> joinChannel(
      {required String channelName, required bool isVideo}) async {
    if (_engine == null) throw Exception('Engine not initialized');

    debugPrint('Joining channel: $channelName | isVideo: $isVideo');

    if (isVideo) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
    }

    await _engine!.joinChannel(
      token: '',
      channelId: channelName,
      uid: 0,
      options: ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        publishCameraTrack: isVideo,
        autoSubscribeAudio: true,
        autoSubscribeVideo: isVideo,
      ),
    );
  }

  Future<void> leaveAndUpdateStatus(
      {required String callId, required String status}) async {
    await _engine?.leaveChannel();
    await Future.delayed(const Duration(milliseconds: 200));
    await _supabase.from('calls').update({
      'status': status,
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', callId);
  }

  Future<void> declineCall(String callId) async {
    await _supabase.from('calls').update({
      'status': 'declined',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', callId);
  }

  Future<void> toggleMute(bool mute) async =>
      _engine?.muteLocalAudioStream(mute);
  Future<void> toggleCamera(bool off) async =>
      _engine?.muteLocalVideoStream(off);
  Future<void> switchCamera() async => _engine?.switchCamera();

  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await Future.delayed(const Duration(milliseconds: 200));
    await _engine?.release();
    _engine = null;
  }

  RtcEngine? get engine => _engine;
}
