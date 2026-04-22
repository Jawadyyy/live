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
    await _engine!.initialize(const RtcEngineContext(appId: appId));
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableAudio();
  }

  Future<Map<String, dynamic>> initiateCall({
    required String receiverId,
    required String callType,
  }) async {
    final callerId = _supabase.auth.currentUser!.id;
    final channelName =
        'call_${callerId.substring(0, 8)}_${receiverId.substring(0, 8)}_${DateTime.now().millisecondsSinceEpoch}';

    final response = await _supabase
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

    return response;
  }

  Future<void> joinChannel({
    required String channelName,
    required bool isVideo,
  }) async {
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
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileCommunication,
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
      ),
    );
  }

  Future<void> leaveAndUpdateStatus({
    required String callId,
    required String status,
  }) async {
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

  Future<void> toggleMute(bool mute) async {
    await _engine?.muteLocalAudioStream(mute);
  }

  Future<void> toggleCamera(bool off) async {
    await _engine?.muteLocalVideoStream(off);
  }

  Future<void> switchCamera() async {
    await _engine?.switchCamera();
  }

  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await _engine?.release();
    _engine = null;
  }

  RtcEngine? get engine => _engine;
}