import '../constants/subscriptions_db_fields.dart';
import 'subscription_plan_model.dart';

final class CompanySubscriptionModel {
  final String id;
  final String companyId;
  final String planId;
  final String status;
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodStart;
  final DateTime? currentPeriodEnd;
  final String? externalProvider;
  final SubscriptionPlanModel plan;

  const CompanySubscriptionModel({
    required this.id,
    required this.companyId,
    required this.planId,
    required this.status,
    required this.plan,
    this.trialEndsAt,
    this.currentPeriodStart,
    this.currentPeriodEnd,
    this.externalProvider,
  });

  factory CompanySubscriptionModel.fromMap(Map<String, dynamic> map) {
    final planMap = Map<String, dynamic>.from(
      map[SubscriptionsDbFields.planRelation] as Map,
    );
    return CompanySubscriptionModel(
      id: map[SubscriptionsDbFields.id] as String,
      companyId: map[SubscriptionsDbFields.companyId] as String,
      planId: map[SubscriptionsDbFields.planId] as String,
      status: map[SubscriptionsDbFields.status] as String,
      trialEndsAt: _toDateTime(map[SubscriptionsDbFields.trialEndsAt]),
      currentPeriodStart: _toDateTime(
        map[SubscriptionsDbFields.currentPeriodStart],
      ),
      currentPeriodEnd: _toDateTime(
        map[SubscriptionsDbFields.currentPeriodEnd],
      ),
      externalProvider: map[SubscriptionsDbFields.externalProvider] as String?,
      plan: SubscriptionPlanModel.fromMap(planMap),
    );
  }

  static DateTime? _toDateTime(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
