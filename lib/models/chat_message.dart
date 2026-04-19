import 'dart:convert';
import 'package:json_annotation/json_annotation.dart';

part 'chat_message.g.dart';

@JsonSerializable()
class ChatMessage {
  final int id;
  final int sessionId;
  final String sender; // 'visitor' or 'admin'
  final String content;
  final int? replyToId;
  final DateTime createdAt;
  final String? type; // 'text', 'voice', etc.
  final Map<String, dynamic>? metadata;

  ChatMessage({
    required this.id,
    required this.sessionId,
    required this.sender,
    required this.content,
    this.replyToId,
    required this.createdAt,
    this.type = 'text',
    this.metadata,
  });

  bool get isFromAdmin => sender == 'admin';
  bool get isFromVisitor => sender == 'visitor';

  VoiceMetadata? get voiceMetadata {
    if (!content.startsWith('[[VOICE_MESSAGE:')) return null;
    try {
      final jsonStr = content.substring('[[VOICE_MESSAGE:'.length, content.length - 2);
      return VoiceMetadata.fromJson(json.decode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) => _$ChatMessageFromJson(json);
  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);
}

@JsonSerializable()
class VoiceMetadata {
  final String url;
  final String pathname;
  final String mimeType;
  final int? durationMs;
  final int? fileSize;
  final String? transcript;

  VoiceMetadata({
    required this.url,
    required this.pathname,
    required this.mimeType,
    this.durationMs,
    this.fileSize,
    this.transcript,
  });

  factory VoiceMetadata.fromJson(Map<String, dynamic> json) => _$VoiceMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$VoiceMetadataToJson(this);
}

class VoiceDraft {
  final String path;
  final int durationMs;
  final String transcript;

  VoiceDraft({
    required this.path,
    required this.durationMs,
    required this.transcript,
  });
}
