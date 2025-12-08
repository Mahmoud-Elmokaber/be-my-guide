import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Helper class that encapsulates Agora engine lifecycle and provides
/// widgets for local/remote video views.
class AgoraLogic {
  AgoraLogic({
    required this.appId,
    this.channel = 'channel1',
    this.token,
    this.onRemoteUserJoined,
    this.onRemoteUserLeft,
  });

  final String appId;
  String channel;
  String? token;
  final Function(int uid)? onRemoteUserJoined;
  final Function(int uid)? onRemoteUserLeft;

  late final RtcEngine _engine;
  bool localUserJoined = false;
  int? remoteUid;

  /// Initialize the Agora engine. Must be called before other operations.
  Future<void> initialize() async {
    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: appId));
    _setupEventHandlers();
  }

  void _setupEventHandlers() {
    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          debugPrint('Local user ${connection.localUid} joined');
          localUserJoined = true;
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          debugPrint('Remote user $remoteUid joined');
          this.remoteUid = remoteUid;
          onRemoteUserJoined?.call(remoteUid);
        },
        onUserOffline:
            (
              RtcConnection connection,
              int remoteUid,
              UserOfflineReasonType reason,
            ) {
              debugPrint('Remote user $remoteUid left');
              this.remoteUid = null;
              onRemoteUserLeft?.call(remoteUid);
            },
      ),
    );
  }

  /// Enable video and start local preview.
  Future<void> setupLocalVideo() async {
    await _engine.enableVideo();
    await _engine.startPreview();
  }

  /// Join the configured channel.
  Future<void> joinChannel() async {
    await _engine.joinChannel(
      token: token ?? '',
      channelId: channel,
      options: const ChannelMediaOptions(
        autoSubscribeVideo: true,
        autoSubscribeAudio: true,
        publishCameraTrack: true,
        publishMicrophoneTrack: true,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
      ),
      uid: 0,
    );
  }

  /// Leave channel and release engine resources.
  Future<void> cleanup() async {
    await _engine.leaveChannel();
    await _engine.release();
  }

  /// Request camera & microphone permissions (platform dialogs).
  Future<void> requestPermissions() async {
    await [
      Permission.microphone,
      Permission.camera,
      Permission.bluetoothConnect, // Required for Android 12+
    ].request();
  }

  /// Widget for local user video.
  Widget localVideoView() {
    return AgoraVideoView(
      controller: VideoViewController(
        rtcEngine: _engine,
        canvas: const VideoCanvas(
          uid: 0,
          renderMode: RenderModeType.renderModeHidden,
        ),
      ),
    );
  }

  /// Widget for remote user video. If no remote user, returns a placeholder.
  Widget remoteVideoView() {
    if (remoteUid != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: remoteUid),
          connection: RtcConnection(channelId: channel),
        ),
      );
    }

    return const Text(
      'Waiting for remote user to join...',
      textAlign: TextAlign.center,
    );
  }

  /// Mute or unmute local audio.
  Future<void> toggleLocalAudio(bool muted) async {
    await _engine.muteLocalAudioStream(muted);
  }

  /// Enable or disable local video.
  Future<void> toggleLocalVideo(bool disabled) async {
    await _engine.muteLocalVideoStream(disabled);
  }

  /// Switch between front and rear cameras.
  Future<void> switchCamera() async {
    await _engine.switchCamera();
  }
}
