import 'plan_limit.dart';

final class SubscriptionPlan {
  final String id;
  final String code;
  final String name;
  final double monthlyPrice;
  final PlanLimit maxUsers;
  final PlanLimit maxVehicles;
  final PlanLimit maxTripsPerMonth;
  final bool hasDriverApp;
  final bool hasAdvancedReports;
  final bool hasDocumentUpload;
  final bool hasMaintenance;
  final bool hasWhatsappNotifications;
  final bool isActive;

  const SubscriptionPlan({
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
}
