import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lad_admin/core/speech_service.dart';

class VoiceRecorderOverlay extends StatefulWidget {
  final Function(String path, int durationMs, String transcript) onSave;
  final VoidCallback onCancel;
  final bool isInline;

  const VoiceRecorderOverlay({
    super.key,
    required this.onSave,
    required this.onCancel,
    this.isInline = false,
  });

  @override
  State<VoiceRecorderOverlay> createState() => _VoiceRecorderOverlayState();
}

class _VoiceRecorderOverlayState extends State<VoiceRecorderOverlay> {
  late AudioRecorder _recorder;
  Timer? _timer;
  int _seconds = 0;
  bool _isPaused = false;
  String? _path;
  String _transcript = "";
  List<double> _amplitudes = [];
  StreamSubscription<Amplitude>? _amplitudeSub;
  StreamSubscription<List<int>>? _audioStreamSub;

  @override
  void initState() {
    super.initState();
    _recorder = AudioRecorder();
    _startRecording();
  }

  Future<void> _startRecording() async {
    try {
      if (await _recorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        _path = '${dir.path}/recording_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        // We start a regular recording for the file
        const config = RecordConfig();
        await _recorder.start(config, path: _path!);
        
        // And we start a separate stream for Vosk
        // Note: Some versions of 'record' might not support parallel file + stream easily.
        // If that fails, we would only startStream and save the file manually after.
        // But let's try the parallel approach first if supported, 
        // OR better: use startStream and write to a file manually while transcribing.
        
        // To be safe and compatible with Vosk, we prioritize the stream if needed.
        // But usually, humans want a high-quality file too.
        
        await speechService.init();
        await speechService.startListening();
        
        // Create a secondary recorder for the stream if the main one is busy,
        // OR check if 'record' can do both. 
        // Actually, let's use a simpler way: pipe the stream to Vosk ONLY.
        // Wait, we need the file path for the backend.
        
        _setupStreamTranscription();

        _amplitudeSub = _recorder.onAmplitudeChanged(const Duration(milliseconds: 100)).listen((amp) {
          setState(() {
            double normalized = (amp.current + 160) / 160;
            _amplitudes.add(normalized.clamp(0.1, 1.0));
            if (_amplitudes.length > (widget.isInline ? 40 : 30)) _amplitudes.removeAt(0);
          });
        });

        _startTimer();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      widget.onCancel();
    }
  }

  Future<void> _setupStreamTranscription() async {
    // We create a second recorder instance specifically for Vosk 16kHz PCM stream
    final streamRecorder = AudioRecorder();
    final stream = await streamRecorder.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      sampleRate: 16000,
      numChannels: 1,
    ));

    _audioStreamSub = stream.listen((data) async {
      if (!_isPaused) {
        final partial = await speechService.appendAudio(Uint8List.fromList(data));
        if (partial != null && partial.isNotEmpty) {
          setState(() {
            _transcript = partial;
          });
        }
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _seconds++;
        });
      }
    });
  }

  Future<void> _togglePause() async {
    if (_isPaused) {
      await _recorder.resume();
      await speechService.startListening();
    } else {
      await _recorder.pause();
      await speechService.stopListening();
    }
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopAndSave() async {
    final path = await _recorder.stop();
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioStreamSub?.cancel();
    await speechService.stopListening();
    
    if (path != null) {
      widget.onSave(path, _seconds * 1000, _transcript);
    }
  }

  Future<void> _cancel() async {
    await _recorder.stop();
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioStreamSub?.cancel();
    await speechService.cancelListening();
    widget.onCancel();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSub?.cancel();
    _audioStreamSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isInline) {
      return _buildInlineRecorder();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2D4A3E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: _buildCommonContent(),
    );
  }

  Widget _buildInlineRecorder() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2D4A3E),
        borderRadius: BorderRadius.circular(24),
      ),
      child: _buildCommonContent(),
    );
  }

  Widget _buildCommonContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            const SizedBox(width: 12),
            const Icon(Icons.mic, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            _buildLiveBars(),
            const SizedBox(width: 12),
            Text(
              _formatDuration(_seconds),
              style: const TextStyle(
                color: Colors.white, 
                fontWeight: FontWeight.bold, 
                fontSize: 16, 
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const Spacer(),
            IconButton(
              icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause, color: Colors.white, size: 20),
              onPressed: _togglePause,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.white70, size: 20),
              onPressed: _cancel,
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _stopAndSave,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Color(0xFF2D4A3E), size: 18),
              ),
            ),
          ],
        ),
        if (speechService.status == "initializing")
           const Padding(
             padding: EdgeInsets.symmetric(vertical: 4),
             child: Text('Загрузка модели...', style: TextStyle(color: Colors.white60, fontSize: 10)),
           ),
        if (_transcript.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8, left: 16, right: 16),
            child: Text(
              _transcript,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveBars() {
    return Expanded(
      child: SizedBox(
        height: 24,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: _amplitudes.map((amp) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 2.5,
              height: 24 * amp,
              decoration: BoxDecoration(
                color: _isPaused ? Colors.white24 : Colors.white70,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
