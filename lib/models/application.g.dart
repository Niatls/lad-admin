// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'application.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Application _$ApplicationFromJson(Map<String, dynamic> json) => Application(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String?,
  phone: json['phone'] as String?,
  gender: json['gender'] as String?,
  age: (json['age'] as num?)?.toInt(),
  reason: json['reason'] as String,
  preferredTime: json['preferredTime'] as String?,
  contactMethod: json['contactMethod'] as String?,
  contactValue: json['contactValue'] as String?,
  verificationCode: json['verificationCode'] as String?,
  telegramId: json['telegramId'] as String?,
  source: json['source'] as String,
  status: json['status'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ApplicationToJson(Application instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'phone': instance.phone,
      'gender': instance.gender,
      'age': instance.age,
      'reason': instance.reason,
      'preferredTime': instance.preferredTime,
      'contactMethod': instance.contactMethod,
      'contactValue': instance.contactValue,
      'verificationCode': instance.verificationCode,
      'telegramId': instance.telegramId,
      'source': instance.source,
      'status': instance.status,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
