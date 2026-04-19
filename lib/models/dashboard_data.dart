import 'package:json_annotation/json_annotation.dart';
import 'application.dart';

part 'dashboard_data.g.dart';

@JsonSerializable()
class DashboardData {
  final List<Application> applications;
  final Map<String, int> totals;
  final int totalApplications;

  DashboardData({
    required this.applications,
    required this.totals,
    required this.totalApplications,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) => _$DashboardDataFromJson(json);
  Map<String, dynamic> toJson() => _$DashboardDataToJson(this);
}
