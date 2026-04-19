import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FfmpegService {
  static const String _ffmpegUrl = 'https://github.com/eugeneware/ffmpeg-static/releases/download/b4.4/win32-x64';
  
  String? _ffmpegPath;
  Completer<void>? _downloadCompleter;

  bool get isDownloading => _downloadCompleter != null && !_downloadCompleter!.isCompleted;

  Future<void> init() async {
    if (_ffmpegPath != null) return;
    
    if (_downloadCompleter != null) {
      await _downloadCompleter!.future;
      return;
    }
    
    _downloadCompleter = Completer<void>();
    
    final appDir = await getApplicationSupportDirectory();
    final exePath = p.join(appDir.path, 'ffmpeg.exe');
    
    if (await File(exePath).exists()) {
      _ffmpegPath = exePath;
      debugPrint('[FfmpegService] FFmpeg found at $_ffmpegPath');
      _downloadCompleter!.complete();
      return;
    }

    try {
      debugPrint('[FfmpegService] Downloading FFmpeg from $_ffmpegUrl...');
      final request = await HttpClient().getUrl(Uri.parse(_ffmpegUrl));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final bytes = await consolidateHttpClientResponseBytes(response);
        await File(exePath).writeAsBytes(bytes);
        _ffmpegPath = exePath;
        debugPrint('[FfmpegService] Download complete. Saved to $_ffmpegPath');
      } else {
        debugPrint('[FfmpegService] Download failed with status: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('[FfmpegService] Download error: $e');
    } finally {
      if (!_downloadCompleter!.isCompleted) {
        _downloadCompleter!.complete();
      }
    }
  }


  /// Converts any audio byte array (WebM/M4A) into raw 16kHz Mono 16-bit PCM using FFmpeg.
  Future<Uint8List?> decodeToPcm(Uint8List audioBytes) async {
    if (_ffmpegPath == null) {
      await init();
    }
    if (_ffmpegPath == null) return null;

    final tempDir = await getTemporaryDirectory();
    final tempInputFile = File(p.join(tempDir.path, 'temp_input_${DateTime.now().millisecondsSinceEpoch}.tmp'));
    
    try {
      await tempInputFile.writeAsBytes(audioBytes);

      // Run FFmpeg to convert input to raw PCM
      // -i input : specifies the input file
      // -f s16le : raw PCM 16-bit little-endian
      // -ar 16000 : 16kHz sample rate
      // -ac 1 : Mono (1 channel)
      // - : outputs to stdout instead of a file
      final process = await Process.run(_ffmpegPath!, [
        '-i', tempInputFile.path,
        '-f', 's16le',
        '-ar', '16000',
        '-ac', '1',
        '-'
      ], stdoutEncoding: null);

      if (process.exitCode != 0) {
        debugPrint('[FfmpegService] FFmpeg Error: ${process.stderr}');
        return null;
      }

      // Process.run stdout is dynamic, but since we set stdoutEncoding: null, it returns List<int>
      final outputBytes = process.stdout as List<int>;
      return Uint8List.fromList(outputBytes);
    } catch (e) {
      debugPrint('[FfmpegService] Decode Error: $e');
      return null;
    } finally {
      if (await tempInputFile.exists()) {
        await tempInputFile.delete();
      }
    }
  }
}

final ffmpegService = FfmpegService();
