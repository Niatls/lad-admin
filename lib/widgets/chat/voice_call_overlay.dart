import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lad_admin/core/voice_call_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class VoiceCallOverlay extends ConsumerStatefulWidget {
  final String token;
  final String participantName;
  final VoidCallback onClose;

  const VoiceCallOverlay({
    super.key,
    required this.token,
    required this.participantName,
    required this.onClose,
  });

  @override
  ConsumerState<VoiceCallOverlay> createState() => _VoiceCallOverlayState();
}



// Correcting the state class name
class _VoiceCallOverlayState extends ConsumerState<VoiceCallOverlay> {
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _isMuted = false;
  String _status = 'Инициализация...';
  Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;


  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _remoteRenderer.initialize();
    
    final service = ref.read(voiceCallServiceProvider(widget.token));
    
    service.statusStream.listen((status) {
      if (mounted) {
        String displayStatus = status;
        if (status == 'Connecting...') displayStatus = 'Подключение...';
        if (status == 'Connected') displayStatus = 'На связи';
        if (status == 'Disconnected') displayStatus = 'Звонок завершён';
        
        setState(() => _status = displayStatus);
        if (status == 'Connected' && !_stopwatch.isRunning) {

          _stopwatch.start();
          _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
        } else if (status == 'Disconnected') {
          _stopwatch.stop();
          _timer?.cancel();
          Future.delayed(const Duration(seconds: 1), widget.onClose);
        }
      }
    });

    service.remoteStreamStream.listen((stream) {
      if (mounted) {
        _remoteRenderer.srcObject = stream;
      }
    });

    await service.start();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String minutes = twoDigits(d.inMinutes.remainder(60));
    String seconds = twoDigits(d.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  void _handleEnd() {
    ref.read(voiceCallServiceProvider(widget.token)).stop();
    widget.onClose();
  }

  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      ref.read(voiceCallServiceProvider(widget.token)).toggleMute(_isMuted);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: const Color(0xFFB5CDB2),
                  child: const Icon(Icons.person, size: 40, color: Color(0xFF2D4A3E)),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),

                const SizedBox(height: 24),
                Text(
                  widget.participantName,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  _status,
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
                if (_stopwatch.isRunning) ...[
                  const SizedBox(height: 16),
                  Text(
                    _formatDuration(_stopwatch.elapsed),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ControlButton(
                      icon: _isMuted ? Icons.mic_off : Icons.mic,
                      color: _isMuted ? Colors.red : Colors.grey[200],
                      iconColor: _isMuted ? Colors.white : Colors.black,
                      onPressed: _toggleMute,
                    ),
                    const SizedBox(width: 40),
                    _ControlButton(
                      icon: Icons.call_end,
                      color: Colors.red,
                      iconColor: Colors.white,
                      onPressed: _handleEnd,
                      size: 72,
                    ),
                    const SizedBox(width: 40),
                    _ControlButton(
                      icon: Icons.volume_up,
                      color: Colors.grey[200],
                      iconColor: Colors.black,
                      onPressed: () {}, // Speaker toggle if needed
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final Color? iconColor;
  final VoidCallback onPressed;
  final double size;

  const _ControlButton({
    required this.icon,
    this.color,
    this.iconColor,
    required this.onPressed,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: size * 0.5),
      ),
    );
  }
}
