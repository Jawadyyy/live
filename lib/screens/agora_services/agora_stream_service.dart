import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AgoraStreamService {
  static const String appId = '3438fb4f909e4753b9f88291f2b22929';
  RtcEngine? _engine;
  final _supabase = Supabase.instance.client;

  RtcEngine? get engine => _engine;

  Future<String> _fetchToken(String channelName,
      {String role = 'publisher'}) async {
    final response = await _supabase.functions.invoke(
      'agora-stream-token',
      body: {'channelName': channelName, 'uid': 0, 'role': role},
    );
    if (response.data == null) throw Exception('Failed to get token');
    return response.data['token'] as String;
  }

  Future<void> initializeBroadcaster() async {
    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await Future.delayed(const Duration(milliseconds: 300));
    await _engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
    await _engine!.enableVideo();
    await _engine!.enableAudio();
    await _engine!.startPreview();
    await _engine!.setVideoEncoderConfiguration(const VideoEncoderConfiguration(
      dimensions: VideoDimensions(width: 1280, height: 720),
      frameRate: 30,
      bitrate: 2000,
    ));
  }

  Future<void> initializeAudience() async {
    _engine = createAgoraRtcEngine();
    await _engine!.initialize(RtcEngineContext(
      appId: appId,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    ));
    await Future.delayed(const Duration(milliseconds: 300));
    await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
    await _engine!.enableVideo();
    await _engine!.muteLocalAudioStream(true);
    await _engine!.muteLocalVideoStream(true);
  }

  Future<void> joinAsBroadcaster(String channelName) async {
    final token = await _fetchToken(channelName, role: 'publisher');
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
        autoSubscribeAudio: false,
        autoSubscribeVideo: false,
      ),
    );
  }

  Future<void> joinAsAudience(String channelName) async {
    final token = await _fetchToken(channelName, role: 'subscriber');
    await _engine!.joinChannel(
      token: token,
      channelId: channelName,
      uid: 0,
      options: const ChannelMediaOptions(
        clientRoleType: ClientRoleType.clientRoleAudience,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        publishMicrophoneTrack: false,
        publishCameraTrack: false,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  Future<void> startScreenShare() async {
    await _engine?.stopPreview();

    await _engine?.startScreenCapture(
      const ScreenCaptureParameters2(
        captureAudio: true,
        captureVideo: true,
        videoParams: ScreenVideoParameters(
          dimensions: VideoDimensions(width: 1280, height: 720),
          frameRate: 15,
          bitrate: 1500,
        ),
      ),
    );

    await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
      publishScreenCaptureVideo: true,
      publishScreenCaptureAudio: true,
      publishCameraTrack: false,
      publishMicrophoneTrack: false,
    ));
  }

  Future<void> stopScreenShare() async {
    await _engine?.stopScreenCapture();
    await _engine?.updateChannelMediaOptions(const ChannelMediaOptions(
      publishCameraTrack: true,
      publishMicrophoneTrack: true,
      publishScreenCaptureVideo: false,
      publishScreenCaptureAudio: false,
    ));
    await _engine?.startPreview();
  }

  Future<void> toggleMute(bool mute) async =>
      _engine?.muteLocalAudioStream(mute);

  Future<void> toggleCamera(bool off) async =>
      _engine?.muteLocalVideoStream(off);

  Future<void> switchCamera() async => _engine?.switchCamera();

  Future<void> updateViewerCount(String streamId, int delta) async {
    final stream = await _supabase
        .from('streams')
        .select('viewer_count')
        .eq('id', streamId)
        .single();
    final current = (stream['viewer_count'] ?? 0) as int;
    await _supabase.from('streams').update({
      'viewer_count': (current + delta).clamp(0, 999999),
    }).eq('id', streamId);
  }

  Future<void> endStream(String streamId) async {
    await _engine?.leaveChannel();
    await _supabase.from('streams').update({
      'status': 'ended',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', streamId);
    await dispose();
  }

  Future<void> leaveAsAudience(String streamId) async {
    await _engine?.leaveChannel();
    await updateViewerCount(streamId, -1);
    await dispose();
  }

  Future<void> dispose() async {
    await _engine?.leaveChannel();
    await Future.delayed(const Duration(milliseconds: 200));
    await _engine?.release();
    _engine = null;
  }
}
