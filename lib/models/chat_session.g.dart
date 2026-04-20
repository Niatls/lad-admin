// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatSession _$ChatSessionFromJson(Map<String, dynamic> json) => ChatSession(
  id: (json['id'] as num).toInt(),
  visitorId: json['visitorId'] as String,
  visitorName: json['visitorName'] as String?,
  status: json['status'] as String,
  lastMessage: json['lastMessage'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  archivedAt: json['archivedAt'] == null
      ? null
      : DateTime.parse(json['archivedAt'] as String),
);

Map<String, dynamic> _$ChatSessionToJson(ChatSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'visitorId': instance.visitorId,
      'visitorName': instance.visitorName,
      'status': instance.status,
      'lastMessage': instance.lastMessage,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'archivedAt': instance.archivedAt?.toIso8601String(),
    };
