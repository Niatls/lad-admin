import 'package:json_annotation/json_annotation.dart';

part 'admin_chat_usage.g.dart';

@JsonSerializable()
class AdminChatUsage {
  final int totalBytes;
  final int monthlyCapBytes;
  final int inviteCount;

  AdminChatUsage({
    required this.totalBytes,
    required this.monthlyCapBytes,
    required this.inviteCount,
  });

  factory AdminChatUsage.fromJson(Map<String, dynamic> json) => _$AdminChatUsageFromJson(json);
  Map<String, dynamic> toJson() => _$AdminChatUsageToJson(this);

  double get percent => (totalBytes / monthlyCapBytes) * 100;
}
