import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:lad_admin/models/chat_message.dart';
import 'package:lad_admin/providers/chat_provider.dart';

class VoiceMessagePlayer extends ConsumerStatefulWidget {
  final VoiceMetadata metadata;
  final bool isFromMe;
  final int messageId;
  final int sessionId;

  const VoiceMessagePlayer({
    super.key,
    required this.metadata,
    required this.isFromMe,
    required this.messageId,
    required this.sessionId,
  });

  @override
  ConsumerState<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends ConsumerState<VoiceMessagePlayer> {
  late AudioPlayer _player;
  bool _showTranscript = false;
  bool _isTranscribing = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      // Suppress Windows plugin errors for unsupported features like speed/pitch adjustment
      try {
        await _player.setSpeed(1.0);
        await _player.setPitch(1.0);
      } catch (_) {
        // Ignore internal plugin errors on Windows
      }

      String url = widget.metadata.url;
      if (url.startsWith('/')) {
        url = 'https://lad-online.vercel.app$url';
      }
      await _player.setUrl(url);
    } catch (e) {
      debugPrint('Error loading audio: $e');
    }
  }


  Future<void> _startTranscription() async {
    setState(() => _isTranscribing = true);
    final success = await ref
        .read(chatMessagesProvider(widget.sessionId).notifier)
        .transcribeMessage(widget.messageId);
    
    if (mounted) {
      setState(() {
        _isTranscribing = false;
        if (success) _showTranscript = true;
      });
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ошибка при расшифровке')),
        );
      }
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isFromMe ? Colors.white : const Color(0xFF2D4A3E);
    final hasTranscript = widget.metadata.transcript != null && widget.metadata.transcript!.isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      width: MediaQuery.of(context).size.width * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPlayBtn(color),
              Expanded(
                child: StreamBuilder<Duration?>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    return ProgressBar(
                      progress: position,
                      total: _player.duration ?? Duration(milliseconds: widget.metadata.durationMs ?? 0),
                      onSeek: _player.seek,
                      progressBarColor: color,
                      baseBarColor: color.withOpacity(0.2),
                      thumbColor: color,
                      timeLabelTextStyle: TextStyle(color: color, fontSize: 10),
                      thumbRadius: 5,
                      barHeight: 3,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              if (_isTranscribing)
                SizedBox(
                  width: 24, height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color.withOpacity(0.5))),
                )
              else if (hasTranscript)
                IconButton(
                  onPressed: () => setState(() => _showTranscript = !_showTranscript),
                  icon: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: _showTranscript ? color : color.withOpacity(0.4)),
                      borderRadius: BorderRadius.circular(4),
                      color: _showTranscript ? color.withOpacity(0.1) : Colors.transparent,
                    ),
                    child: Text(
                      'Aa',
                      style: TextStyle(
                        color: color, 
                        fontSize: 12, 
                        fontWeight: _showTranscript ? FontWeight.bold : FontWeight.normal
                      ),
                    ),
                  ),
                  tooltip: 'Показать/скрыть текст',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                )
              else
                IconButton(
                  onPressed: _startTranscription,
                  icon: Icon(Icons.spellcheck, color: color.withOpacity(0.6), size: 20),
                  tooltip: 'Распознать текст (Whisper)',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              const SizedBox(width: 4),
            ],
          ),
          if (hasTranscript && _showTranscript)
            Padding(
              padding: const EdgeInsets.only(left: 12, top: 4, right: 12),
              child: SelectableText(
                widget.metadata.transcript!,
                style: TextStyle(
                  color: color.withOpacity(0.85),
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayBtn(Color color) {
    return StreamBuilder<PlayerState>(
      stream: _player.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing;
        
        if (processingState == ProcessingState.loading || processingState == ProcessingState.buffering) {
          return Container(
            margin: const EdgeInsets.all(12),
            width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(color)),
          );
        } else if (playing != true) {
          return IconButton(
            icon: Icon(Icons.play_arrow_rounded, color: color, size: 28),
            onPressed: _player.play,
          );
        } else if (processingState != ProcessingState.completed) {
          return IconButton(
            icon: Icon(Icons.pause_rounded, color: color, size: 28),
            onPressed: _player.pause,
          );
        } else {
          return IconButton(
            icon: Icon(Icons.replay_rounded, color: color, size: 28),
            onPressed: () => _player.seek(Duration.zero),
          );
        }
      },
    );
  }
}
