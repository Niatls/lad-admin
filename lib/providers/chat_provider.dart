import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lad_admin/core/api_client.dart';
import 'package:lad_admin/core/speech_service.dart';
import 'package:lad_admin/models/chat_session.dart';
import 'package:lad_admin/models/chat_message.dart';
import 'package:lad_admin/models/admin_chat_usage.dart';

final apiClientProvider = Provider((ref) => ApiClient());

/// Provider for the list of all chat sessions
final chatSessionsProvider = StateNotifierProvider<ChatSessionsNotifier, AsyncValue<List<ChatSession>>>((ref) {
  return ChatSessionsNotifier(ref.watch(apiClientProvider), ref);
});

/// Provider for a single session's details
final sessionDetailsProvider = FutureProvider.family<ChatSession, int>((ref, sessionId) async {
  final api = ref.watch(apiClientProvider);
  final response = await api.get('/admin/chat/sessions');
  final List<dynamic> data = response.data['sessions'];
  final sessions = data.map((json) => ChatSession.fromJson(json)).toList();
  return sessions.firstWhere((s) => s.id == sessionId);
});

/// Provider for chat usage statistics
final chatUsageProvider = StateProvider<AdminChatUsage?>((ref) => null);

class ChatSessionsNotifier extends StateNotifier<AsyncValue<List<ChatSession>>> {
  final ApiClient _api;
  final Ref _ref;
  Timer? _timer;

  ChatSessionsNotifier(this._api, this._ref) : super(const AsyncValue.loading()) {
    fetchSessions();
    // Refresh sessions list every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => fetchSessions());
  }

  Future<void> fetchSessions() async {
    try {
      final response = await _api.get('/admin/chat/sessions');
      final List<dynamic> data = response.data['sessions'];
      final sessions = data.map((json) => ChatSession.fromJson(json)).toList();
      
      if (response.data['usage'] != null) {
        _ref.read(chatUsageProvider.notifier).state = AdminChatUsage.fromJson(response.data['usage']);
      }
      
      state = AsyncValue.data(sessions);
    } catch (e, st) {
      if (state is! AsyncData) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

/// Provider for messages in a specific session
final chatMessagesProvider = StateNotifierProvider.family<ChatMessagesNotifier, AsyncValue<List<ChatMessage>>, int>((ref, sessionId) {
  return ChatMessagesNotifier(ref.watch(apiClientProvider), sessionId);
});

class ChatMessagesNotifier extends StateNotifier<AsyncValue<List<ChatMessage>>> {
  final ApiClient _api;
  final int sessionId;
  Timer? _pollingTimer;

  ChatMessagesNotifier(this._api, this.sessionId) : super(const AsyncValue.loading()) {
    fetchMessages();
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages(quiet: true));
  }

  Future<void> fetchMessages({bool quiet = false}) async {
    if (!quiet) state = const AsyncValue.loading();
    try {
      final response = await _api.get('/chat/sessions/$sessionId/messages');
      final List<dynamic> data = response.data;
      final messages = data.map((json) => ChatMessage.fromJson(json)).toList();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      if (!quiet) state = AsyncValue.error(e, st);
    }
  }

  Future<bool> sendMessage(String content, {int? replyToId}) async {
    try {
      await _api.post('/chat/sessions/$sessionId/messages', data: {
        'content': content,
        'sender': 'admin',
        if (replyToId != null) 'replyToId': replyToId,
      });
      await fetchMessages(quiet: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> sendVoiceMessage(String filePath, int durationMs, {int? replyToId, String? transcript}) async {
    try {
      final file = File(filePath);
      final fileName = file.path.split('/').last;
      
      final formData = FormData.fromMap({
        'sender': 'admin',
        'durationMs': durationMs.toString(),
        if (transcript != null) 'transcript': transcript,
        if (replyToId != null) 'replyToId': replyToId.toString(),
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });

      await _api.post('/chat/sessions/$sessionId/voice-message', data: formData);
      await fetchMessages(quiet: true);
      return true;
    } catch (e) {
      print('Voice upload error: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(int messageId) async {
    return deleteMessages([messageId]);
  }

  Future<bool> deleteMessages(List<int> messageIds) async {
    try {
      await _api.delete('/admin/chat/sessions/$sessionId/messages', data: {
        'messageIds': messageIds,
      });
      await fetchMessages(quiet: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> archiveSession() async {
    try {
      await _api.delete('/admin/chat/sessions/$sessionId', data: {'mode': 'soft'});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteSession() async {
    try {
      await _api.delete('/admin/chat/sessions/$sessionId', data: {'mode': 'hard'});
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String?> generateVoiceToken() async {
    try {
      final response = await _api.post(
        '/admin/chat/sessions/$sessionId/voice-token',
        data: {'source': 'native'},
      );

      return response.data['token'];
    } catch (e) {
      return null;
    }
  }


  Future<bool> editMessage(int messageId, String newContent) async {
    try {
      await _api.patch('/chat/sessions/$sessionId/messages/$messageId', data: {
        'content': newContent,
      });
      await fetchMessages(quiet: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> transcribeMessage(int messageId) async {
    try {
      final messages = state.asData?.value;
      if (messages == null) return false;
      
      final message = messages.firstWhere((m) => m.id == messageId);
      final metadata = message.voiceMetadata;
      if (metadata == null) return false;

      // 1. Download audio file
      String url = metadata.url;
      if (url.startsWith('/')) {
        url = 'https://lad-online.vercel.app$url';
      }
      
      final response = await Dio().get<List<int>>(
        url, 
        options: Options(responseType: ResponseType.bytes),
      );
      
      if (response.data == null) return false;
      final bytes = Uint8List.fromList(response.data!);

      // 2. Transcribe locally (Free/Offline)
      final transcript = await speechService.transcribeFile(bytes);
      if (transcript.isEmpty) return false;

      // 3. Save to server (pass transcript in body to bypass Whisper on server)
      await _api.post('/chat/sessions/$sessionId/messages/$messageId/transcribe', data: {
        'transcript': transcript,
      });
      
      await fetchMessages(quiet: true);
      return true;
    } catch (e) {
      print('Local transcription error: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
