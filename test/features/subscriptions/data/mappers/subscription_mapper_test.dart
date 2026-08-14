import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/subscriptions/data/mappers/subscription_mapper.dart';
import 'package:horus_system/features/subscriptions/data/models/company_subscription_model.dart';
import 'package:horus_system/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:horus_system/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:test/test.dart';

void main() {
  test('plan mapper treats null limits as unlimited', () {
    final entity = _planModel(maxUsers: null).toEntity();

    expect(entity.maxUsers.isUnlimited, isTrue);
    expect(entity.maxVehicles.value, 20);
    expect(entity.maxTripsPerMonth.value, 500);
  });

  test('company subscription mapper parses typed status and plan', () {
    final result = _subscriptionModel(status: 'past_due').toEntityResult();
    final entity = result.dataOrNull;

    expect(entity?.status, SubscriptionStatus.pastDue);
    expect(entity?.plan.code, 'basic');
  });

  test('company subscription mapper rejects unknown status', () {
    final result = _subscriptionModel(status: 'paused').toEntityResult();

    expect(result.failureOrNull?.code, FailureCodes.subscriptionStatusInvalid);
  });
}

CompanySubscriptionModel _subscriptionModel({required String status}) {
  return CompanySubscriptionModel(
    id: 'subscription-1',
    companyId: 'company-1',
    planId: 'plan-basic',
    status: status,
    plan: _planModel(),
  );
}

SubscriptionPlanModel _planModel({int? maxUsers = 5}) {
  return SubscriptionPlanModel(
    id: 'plan-basic',
    code: 'basic',
    name: 'Basic',
    monthlyPrice: 100,
    maxUsers: maxUsers,
    maxVehicles: 20,
    maxTripsPerMonth: 500,
    hasDriverApp: true,
    hasAdvancedReports: false,
    hasDocumentUpload: false,
    hasMaintenance: false,
    hasWhatsappNotifications: false,
    isActive: true,
  );
}
