import '../constants/subscriptions_db_fields.dart';

final class SubscriptionPlanModel {
  final String id;
  final String code;
  final String name;
  final double monthlyPrice;
  final int? maxUsers;
  final int? maxVehicles;
  final int? maxTripsPerMonth;
  final bool hasDriverApp;
  final bool hasAdvancedReports;
  final bool hasDocumentUpload;
  final bool hasMaintenance;
  final bool hasWhatsappNotifications;
  final bool isActive;

  const SubscriptionPlanModel({
    required this.id,
    required this.code,
    required this.name,
    required this.monthlyPrice,
    required this.maxUsers,
    required this.maxVehicles,
    required this.maxTripsPerMonth,
    required this.hasDriverApp,
    required this.hasAdvancedReports,
    required this.hasDocumentUpload,
    required this.hasMaintenance,
    required this.hasWhatsappNotifications,
    required this.isActive,
  });

  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> map) {
    return SubscriptionPlanModel(
      id: map[SubscriptionsDbFields.id] as String,
      code: map[SubscriptionsDbFields.code] as String,
      name: map[SubscriptionsDbFields.name] as String,
      monthlyPrice: _toDouble(map[SubscriptionsDbFields.monthlyPrice]),
      maxUsers: _toInt(map[SubscriptionsDbFields.maxUsers]),
      maxVehicles: _toInt(map[SubscriptionsDbFields.maxVehicles]),
      maxTripsPerMonth: _toInt(map[SubscriptionsDbFields.maxTripsPerMonth]),
      hasDriverApp: map[SubscriptionsDbFields.hasDriverApp] as bool? ?? false,
      hasAdvancedReports:
          map[SubscriptionsDbFields.hasAdvancedReports] as bool? ?? false,
      hasDocumentUpload:
          map[SubscriptionsDbFields.hasDocumentUpload] as bool? ?? false,
      hasMaintenance:
          map[SubscriptionsDbFields.hasMaintenance] as bool? ?? false,
      hasWhatsappNotifications:
          map[SubscriptionsDbFields.hasWhatsappNotifications] as bool? ?? false,
      isActive: map[SubscriptionsDbFields.isActive] as bool? ?? true,
    );
  }

  static double _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int? _toInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}
