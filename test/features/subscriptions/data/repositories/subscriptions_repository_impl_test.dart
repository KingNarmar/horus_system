import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/subscriptions/data/datasources/subscriptions_remote_data_source.dart';
import 'package:horus_system/features/subscriptions/data/models/company_subscription_model.dart';
import 'package:horus_system/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:horus_system/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:test/test.dart';

void main() {
  test('getAvailablePlans maps remote models to entities', () async {
    final remote = _FakeSubscriptionsRemoteDataSource(plans: [_planModel()]);
    final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

    final result = await repository.getAvailablePlans();

    expect(result.dataOrNull?.single.code, 'basic');
  });

  test(
    'getCurrentCompanySubscription trims and scopes by company id',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource(
        subscription: _subscriptionModel(status: 'active'),
      );
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: ' company-1 ',
      );

      expect(result.dataOrNull?.companyId, 'company-1');
      expect(remote.requestedCompanyIds, ['company-1']);
    },
  );

  test(
    'getCurrentCompanySubscription returns success null when not seeded',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource();
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: 'company-1',
      );

      expect(result.dataOrNull, isNull);
      expect(result.isSuccess, isTrue);
    },
  );

  test(
    'getCurrentCompanySubscription validates company id before remote call',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource();
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: ' ',
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.validationCompanyIdRequired,
      );
      expect(remote.requestedCompanyIds, isEmpty);
    },
  );

  test(
    'getCurrentCompanySubscription exposes invalid status failure',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource(
        subscription: _subscriptionModel(status: 'paused'),
      );
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: 'company-1',
      );

      expect(
        result.failureOrNull?.code,
        FailureCodes.subscriptionStatusInvalid,
      );
    },
  );
}

final class _FakeSubscriptionsRemoteDataSource
    implements SubscriptionsRemoteDataSource {
  _FakeSubscriptionsRemoteDataSource({
    this.plans = const [],
    this.subscription,
  });

  final List<SubscriptionPlanModel> plans;
  final CompanySubscriptionModel? subscription;
  final requestedCompanyIds = <String>[];

  @override
  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    return plans;
  }

  @override
  Future<CompanySubscriptionModel?> getCurrentCompanySubscription({
    required String companyId,
  }) async {
    requestedCompanyIds.add(companyId);
    return subscription;
  }
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

SubscriptionPlanModel _planModel() {
  return const SubscriptionPlanModel(
    id: 'plan-basic',
    code: 'basic',
    name: 'Basic',
    monthlyPrice: 100,
    maxUsers: 5,
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
