import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vosk_flutter/vosk_flutter.dart';
import 'package:lad_admin/core/ffmpeg_service.dart';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class SpeechService {
  final VoskFlutterPlugin _vosk = VoskFlutterPlugin.instance();
  Model? _model;
  Recognizer? _recognizer;
  
  bool _isInitialized = false;
  String _lastError = "";
  String _status = "idle";
  bool _isListening = false;

  Future<bool> init() async {
    if (_isInitialized) return true;
    try {
      debugPrint('[SpeechService] Initializing Vosk (Direct)...');
      _status = "initializing";
      
      // We manually extract the zip to avoid ModelLoader bugs on Windows
      final appDir = await getApplicationSupportDirectory();
      final modelDir = p.join(appDir.path, 'vosk-model-small-ru');
      
      if (!await File(p.join(modelDir, 'am', 'final.mdl')).exists()) {
        debugPrint('[SpeechService] Extracting model zip to $modelDir...');
        final zipData = await rootBundle.load('assets/models/vosk-model-small-ru.zip');
        final bytes = zipData.buffer.asUint8List(zipData.offsetInBytes, zipData.lengthInBytes);
        final archive = ZipDecoder().decodeBytes(bytes);
        
        for (final file in archive) {
          final filename = file.name;
          if (file.isFile) {
            final data = file.content as List<int>;
            final f = File(p.join(modelDir, filename));
            await f.create(recursive: true);
            await f.writeAsBytes(data);
          } else {
            Directory(p.join(modelDir, filename)).createSync(recursive: true);
          }
        }
      }

      debugPrint('[SpeechService] Loading model from $modelDir');
      _model = await _vosk.createModel(modelDir);
      _recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      
      _isInitialized = true;
      _status = "ready";
      debugPrint('[SpeechService] Vosk Ready.');
      return true;
    } catch (e) {
      _lastError = e.toString();
      _status = "error";
      debugPrint('[SpeechService] Vosk Init Error: $e');
      return false;
    }
  }

  /// Transcribe an audio file (bytes) by decoding to PCM (via FFmpeg) and feeding to Vosk.
  Future<String> transcribeFile(Uint8List audioBytes) async {
    if (!_isInitialized) {
      await init();
    }
    if (!_isInitialized || _model == null) return "";

    try {
      debugPrint('[SpeechService] Decoding file to PCM via FFmpeg...');
      final pcmBytes = await ffmpegService.decodeToPcm(audioBytes);

      if (pcmBytes == null || pcmBytes.isEmpty) {
        debugPrint('[SpeechService] PCM decoding failed or returned empty.');
        return "";
      }

      debugPrint('[SpeechService] Transcribing PCM (${pcmBytes.length} bytes)...');
      // Use a dedicated recognizer for this file
      final recognizer = await _vosk.createRecognizer(model: _model!, sampleRate: 16000);
      await recognizer.acceptWaveformBytes(pcmBytes);
      final result = await recognizer.getResult();
      
      return _extractText(result);
    } catch (e) {
      debugPrint('[SpeechService] Transcribe File Error: $e');
      return "";
    }
  }

  Future<void> startListening() async {
    if (!_isInitialized) {
      await init();
    }
    if (_isInitialized) {
      _isListening = true;
      _status = "listening";
      debugPrint('[SpeechService] Start Listening (Vosk)');
    }
  }

  /// Push audio bytes to the recognizer.
  /// Expects PCM 16-bit Mono @ 16kHz
  Future<String?> appendAudio(Uint8List bytes) async {
    if (!_isListening || _recognizer == null) return null;
    
    try {
      final isFinal = await _recognizer!.acceptWaveformBytes(bytes);
      if (isFinal) {
        final result = await _recognizer!.getResult();
        debugPrint('[SpeechService] Raw Final Result: $result');
        return _extractText(result);
      } else {
        final partial = await _recognizer!.getPartialResult();
        debugPrint('[SpeechService] Raw Partial Result: $partial');
        return _extractPartialText(partial);
      }
    } catch (e) {
      debugPrint('[SpeechService] Append Audio Error: $e');
      return null;
    }
  }

  String _extractText(dynamic result) {
    try {
      if (result is String) {
        final map = json.decode(result);
        return map['text'] ?? "";
      }
      return result.text ?? ""; // If it's already an object
    } catch (e) {
      debugPrint('[SpeechService] Error parsing final text: $e');
      return result.toString();
    }
  }

  String _extractPartialText(dynamic partial) {
    try {
      if (partial is String) {
        final map = json.decode(partial);
        return map['partial'] ?? "";
      }
      return partial.partial ?? "";
    } catch (e) {
      debugPrint('[SpeechService] Error parsing partial text: $e');
      return partial.toString();
    }
  }

  Future<void> stopListening() async {
    debugPrint('[SpeechService] Stopping (Vosk)...');
    _isListening = false;
    _status = "idle";
  }

  Future<void> cancelListening() async {
    debugPrint('[SpeechService] Cancelling (Vosk)...');
    _isListening = false;
    _status = "idle";
  }

  bool get isListening => _isListening;
  bool get isAvailable => _isInitialized;
  String get lastError => _lastError;
  String get status => _status;
}

final speechService = SpeechService();
