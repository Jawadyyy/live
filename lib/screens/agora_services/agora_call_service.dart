import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:live/config/app_config.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AgoraCallService {
  static const String appId = AppConfig.agoraAppId;
  RtcEngine? _engine;
  final _supabase = Supabase.instance.client;

  Future<String> _fetchToken(String channelName) async {
    final response = await _supabase.functions.invoke(
      'agora-stream-token',
      body: {'channelName': channelName, 'uid': 0},
    );
    if (response.data == null) throw Exception('Failed to get token');
    return response.data['token'] as String;
  }

  Future<void> initialize() async {
    final statuses = await [Permission.microphone, Permission.camera].request();
    if (!(statuses[Permission.microphone]?.isGranted ?? false)) {
      throw Exception('Microphone permission denied');
    }

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    await Future.delayed(const Duration(milliseconds: 500));
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
  }

  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String callType,
  }) async {
    final callerId = _supabase.auth.currentUser!.id;
    final channelName =
        'ch_${callerId.substring(0, 6)}_${receiverId.substring(0, 6)}_${DateTime.now().millisecondsSinceEpoch}';

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

  Future<void> joinChannel({
    required String channelName,
    required bool isVideo,
  }) async {
    if (_engine == null) throw Exception('Engine not initialized');

    final token = await _fetchToken(channelName);
    debugPrint('Token fetched successfully');

    if (isVideo) {
      await _engine!.enableVideo();
      await _engine!.startPreview();
    } else {
      await _engine!.disableVideo();
    }

    await _engine!.joinChannel(
      token: token,
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

  Future<void> leaveAndUpdateStatus({
    required String callId,
    required String status,
  }) async {
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
