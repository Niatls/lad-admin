import 'package:json_annotation/json_annotation.dart';

part 'application.g.dart';

@JsonSerializable()
class Application {
  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? gender;
  final int? age;
  final String reason;
  final String? preferredTime;
  final String? contactMethod;
  final String? contactValue;
  final String? verificationCode;
  final String? telegramId;
  final String source;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Application({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.gender,
    this.age,
    required this.reason,
    this.preferredTime,
    this.contactMethod,
    this.contactValue,
    this.verificationCode,
    this.telegramId,
    required this.source,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Application.fromJson(Map<String, dynamic> json) => _$ApplicationFromJson(json);
  Map<String, dynamic> toJson() => _$ApplicationToJson(this);
}
