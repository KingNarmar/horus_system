import 'dart:collection';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/subscriptions/data/datasources/subscriptions_remote_data_source.dart';
import 'package:horus_system/features/subscriptions/data/models/company_subscription_model.dart';
import 'package:horus_system/features/subscriptions/data/models/subscription_plan_model.dart';
import 'package:horus_system/features/subscriptions/data/repositories/subscriptions_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import 'package:test/test.dart';

void main() {
  test('getAvailablePlans maps remote models to entities', () async {
    final remote = _FakeSubscriptionsRemoteDataSource(plans: [_planModel()]);
    final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

    final result = await repository.getAvailablePlans();

    expect(result.dataOrNull?.single.code, 'basic');
  });

  test(
    'getCurrentCompanySubscription forwards the exact company id it receives',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource(
        subscription: _subscriptionModel(status: 'active'),
      );
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: ' company-1 ',
      );

      expect(result.dataOrNull?.companyId, 'company-1');
      expect(remote.requestedCompanyIds, [' company-1 ']);
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
    'getCurrentCompanySubscription exposes sanitized invalid status failure',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource(
        subscription: _subscriptionModel(status: 'paused'),
      );
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isA<ServerFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.subscriptionStatusInvalid,
      );
      expect(result.failureOrNull?.message, isNull);
    },
  );

  test(
    'getCurrentCompanySubscription maps 42501 through sanitized feature mapper',
    () async {
      final remote = _FakeSubscriptionsRemoteDataSource(
        subscriptionError: const PostgrestException(
          message: 'permission denied',
          code: '42501',
          details: 'internal permission details',
          hint: 'internal permission hint',
        ),
      );
      final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

      final result = await repository.getCurrentCompanySubscription(
        companyId: 'company-1',
      );

      expect(result.failureOrNull, isA<PermissionFailure>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.permissionSubscriptionsView,
      );
      expect(result.failureOrNull?.message, isNull);
      expect(remote.requestedCompanyIds, ['company-1']);
    },
  );

  test('getAvailablePlans sanitizes generic Postgrest failure', () async {
    final remote = _FakeSubscriptionsRemoteDataSource(
      plansError: const PostgrestException(
        message: 'database unavailable',
        code: 'PGRST500',
        details: 'internal database details',
        hint: 'internal database hint',
      ),
    );
    final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

    final result = await repository.getAvailablePlans();

    expect(result.failureOrNull, isA<ServerFailure>());
    expect(result.failureOrNull?.code, FailureCodes.serverError);
    expect(result.failureOrNull?.message, isNull);
  });

  test('getAvailablePlans sanitizes unexpected failure', () async {
    final error = StateError('unexpected runtime details');
    final remote = _FakeSubscriptionsRemoteDataSource(plansError: error);
    final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

    final result = await repository.getAvailablePlans();

    expect(result.failureOrNull, isA<UnexpectedFailure>());
    expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
    expect(result.failureOrNull?.message, isNull);
  });

  test('plan mapping failure stays inside repository boundary', () async {
    final remote = _FakeSubscriptionsRemoteDataSource(
      plans: _ThrowingSubscriptionPlanList(),
    );
    final repository = SubscriptionsRepositoryImpl(remoteDataSource: remote);

    final result = await repository.getAvailablePlans();

    expect(result.failureOrNull, isA<UnexpectedFailure>());
    expect(result.failureOrNull?.code, FailureCodes.unexpectedError);
    expect(result.failureOrNull?.message, isNull);
  });
}

final class _FakeSubscriptionsRemoteDataSource
    implements SubscriptionsRemoteDataSource {
  _FakeSubscriptionsRemoteDataSource({
    this.plans = const [],
    this.subscription,
    this.plansError,
    this.subscriptionError,
  });

  final List<SubscriptionPlanModel> plans;
  final CompanySubscriptionModel? subscription;
  final Object? plansError;
  final Object? subscriptionError;
  final requestedCompanyIds = <String>[];

  @override
  Future<List<SubscriptionPlanModel>> getAvailablePlans() async {
    if (plansError != null) throw plansError!;
    return plans;
  }

  @override
  Future<CompanySubscriptionModel?> getCurrentCompanySubscription({
    required String companyId,
  }) async {
    requestedCompanyIds.add(companyId);
    if (subscriptionError != null) throw subscriptionError!;
    return subscription;
  }
}

final class _ThrowingSubscriptionPlanList
    extends ListBase<SubscriptionPlanModel> {
  @override
  int get length => 1;

  @override
  set length(int _) => throw UnsupportedError('test-only list');

  @override
  SubscriptionPlanModel operator [](int index) {
    throw StateError('subscription plan mapping failed');
  }

  @override
  void operator []=(int index, SubscriptionPlanModel value) {
    throw UnsupportedError('test-only list');
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
