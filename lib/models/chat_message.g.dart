// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: (json['id'] as num).toInt(),
  sessionId: (json['sessionId'] as num).toInt(),
  sender: json['sender'] as String,
  content: json['content'] as String,
  replyToId: (json['replyToId'] as num?)?.toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  type: json['type'] as String? ?? 'text',
  metadata: json['metadata'] as Map<String, dynamic>?,
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'sender': instance.sender,
      'content': instance.content,
      'replyToId': instance.replyToId,
      'createdAt': instance.createdAt.toIso8601String(),
      'type': instance.type,
      'metadata': instance.metadata,
    };

VoiceMetadata _$VoiceMetadataFromJson(Map<String, dynamic> json) =>
    VoiceMetadata(
      url: json['url'] as String,
      pathname: json['pathname'] as String,
      mimeType: json['mimeType'] as String,
      durationMs: (json['durationMs'] as num?)?.toInt(),
      fileSize: (json['fileSize'] as num?)?.toInt(),
      transcript: json['transcript'] as String?,
    );

Map<String, dynamic> _$VoiceMetadataToJson(VoiceMetadata instance) =>
    <String, dynamic>{
      'url': instance.url,
      'pathname': instance.pathname,
      'mimeType': instance.mimeType,
      'durationMs': instance.durationMs,
      'fileSize': instance.fileSize,
      'transcript': instance.transcript,
    };
