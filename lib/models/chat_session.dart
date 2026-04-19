import 'package:json_annotation/json_annotation.dart';

part 'chat_session.g.dart';

@JsonSerializable()
class ChatSession {
  final int id;
  final String visitorId;
  final String? visitorName;
  final String status;
  final String? lastMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatSession({
    required this.id,
    required this.visitorId,
    this.visitorName,
    required this.status,
    this.lastMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatSession.fromJson(Map<String, dynamic> json) => _$ChatSessionFromJson(json);
  Map<String, dynamic> toJson() => _$ChatSessionToJson(this);
}
