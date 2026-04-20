// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_chat_usage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminChatUsage _$AdminChatUsageFromJson(Map<String, dynamic> json) =>
    AdminChatUsage(
      totalBytes: (json['totalBytes'] as num).toInt(),
      monthlyCapBytes: (json['monthlyCapBytes'] as num).toInt(),
      inviteCount: (json['inviteCount'] as num).toInt(),
    );

Map<String, dynamic> _$AdminChatUsageToJson(AdminChatUsage instance) =>
    <String, dynamic>{
      'totalBytes': instance.totalBytes,
      'monthlyCapBytes': instance.monthlyCapBytes,
      'inviteCount': instance.inviteCount,
    };
