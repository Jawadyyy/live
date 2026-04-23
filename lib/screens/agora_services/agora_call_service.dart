import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AgoraCallService {
  static const String appId = '3438fb4f909e4753b9f88291f2b22929';
  RtcEngine? _engine;
  final _supabase = Supabase.instance.client;

  Future<void> initialize() async {
    await [Permission.microphone, Permission.camera].request();
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileCommunication,
    ));
    await _engine!.enableAudio();
    await _engine!.setEnableSpeakerphone(true);
    await _engine!.setAudioProfile(
      profile: AudioProfileType.audioProfileDefault,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
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

  Future<void> joinChannel(
      {required String channelName, required bool isVideo}) async {
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
    await _engine?.release();
    _engine = null;
  }

  RtcEngine? get engine => _engine;
}
