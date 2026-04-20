import 'dart:async';
import 'dart:convert';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lad_admin/core/api_client.dart';
import 'package:lad_admin/providers/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


class VoiceCallService {
  final ApiClient _api;
  final String token;
  final String role = 'admin';

  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  Timer? _pollingTimer;
  int _lastSignalId = 0;
  
  final _statusController = StreamController<String>.broadcast();
  final _remoteStreamController = StreamController<MediaStream?>.broadcast();
  final _statsController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<String> get statusStream => _statusController.stream;
  Stream<MediaStream?> get remoteStreamStream => _remoteStreamController.stream;
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  VoiceCallService(this._api, this.token);

  Future<void> start() async {
    _statusController.add('Connecting...');
    
    // 1. Initial setup
    await _initPeerConnection();
    await _startSignaling();
    
    // 2. Initial offer (Admin usually sends the offer in this specific protocol)
    await _createAndSendOffer();
  }

  Future<void> _initPeerConnection() async {
    final Map<String, dynamic> configuration = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ]
    };

    _peerConnection = await createPeerConnection(configuration);

    _peerConnection!.onIceCandidate = (candidate) {
      if (candidate == null) return;
      _postSignal('candidate', {
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteStream = event.streams[0];
        _remoteStreamController.add(_remoteStream);
        _statusController.add('Connected');
      }
    };

    _peerConnection!.onConnectionState = (state) {
      _statusController.add(state.toString());
    };

    // Acquire microphone
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': false,
    };
    _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
    
    _localStream!.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });
  }

  Future<void> _startSignaling() async {
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) => _pollSignals());
  }

  Future<void> _pollSignals() async {
    try {
      final response = await _api.get('/native/chat/voice/$token/signals', queryParameters: {
        'role': role,
        'after': _lastSignalId,
      });
      
      final List<dynamic> signals = response.data;
      for (final signal in signals) {
        _lastSignalId = (signal['id'] as num).toInt();
        await _handleSignal(signal['signalType'], signal['payload']);
      }
      
      // Also check if invite is still active
      final inviteRes = await _api.get('/native/chat/voice/$token');
      // If 404/410, end call
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _handleSignal(String type, dynamic payload) async {
    if (type == 'answer') {
      final description = RTCSessionDescription(payload['sdp'], payload['type']);
      await _peerConnection!.setRemoteDescription(description);
    } else if (type == 'candidate') {
      final candidate = RTCIceCandidate(
        payload['candidate'],
        payload['sdpMid'],
        payload['sdpMLineIndex'],
      );
      await _peerConnection!.addCandidate(candidate);
    } else if (type == 'hangup') {
      stop();
    }
  }

  Future<void> _createAndSendOffer() async {
    final RTCSessionDescription offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);
    
    await _postSignal('offer', {
      'sdp': offer.sdp,
      'type': offer.type,
    });
  }

  Future<void> _postSignal(String type, dynamic payload) async {
    await _api.post('/native/chat/voice/$token/signals', data: {
      'role': role,
      'signalType': type,
      'payload': payload,
    });
  }

  void toggleMute(bool muted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !muted;
    });
  }

  Future<void> stop() async {
    _pollingTimer?.cancel();
    await _postSignal('hangup', null);
    
    await _localStream?.dispose();
    await _peerConnection?.close();
    await _peerConnection?.dispose();
    
    _localStream = null;
    _peerConnection = null;
    
    _statusController.add('Disconnected');
    _remoteStreamController.add(null);
  }

  void dispose() {
    stop();
    _statusController.close();
    _remoteStreamController.close();
    _statsController.close();
  }
}

final voiceCallServiceProvider = Provider.family<VoiceCallService, String>((ref, token) {
  final api = ref.watch(apiClientProvider);
  return VoiceCallService(api, token);
});
