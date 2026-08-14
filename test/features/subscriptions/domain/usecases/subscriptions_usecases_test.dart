import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_subscription.dart';
import 'package:horus_system/features/subscriptions/domain/entities/plan_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:horus_system/features/subscriptions/domain/entities/subscription_status.dart';
import 'package:horus_system/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_available_subscription_plans_usecase.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_current_company_subscription_usecase.dart';
import 'package:test/test.dart';

void main() {
  test('available plans use case allows owners and calls repository', () async {
    final repository = _FakeSubscriptionsRepository();
    final useCase = GetAvailableSubscriptionPlansUseCase(repository);

    final result = await useCase(
      GetAvailableSubscriptionPlansParams(currentCompanyContext: _context()),
    );

    expect(result.dataOrNull, repository.plans);
    expect(repository.availablePlansCalls, 1);
  });

  test('available plans use case blocks non-owner roles', () async {
    final repository = _FakeSubscriptionsRepository();
    final useCase = GetAvailableSubscriptionPlansUseCase(repository);

    final result = await useCase(
      GetAvailableSubscriptionPlansParams(
        currentCompanyContext: _context(role: CompanyRole.admin),
      ),
    );

    expect(result.failureOrNull, isA<PermissionFailure>());
    expect(
      result.failureOrNull?.code,
      FailureCodes.permissionSubscriptionsView,
    );
    expect(repository.availablePlansCalls, 0);
  });

  test(
    'current subscription use case scopes lookup to current company',
    () async {
      final repository = _FakeSubscriptionsRepository();
      final useCase = GetCurrentCompanySubscriptionUseCase(repository);

      final result = await useCase(
        GetCurrentCompanySubscriptionParams(currentCompanyContext: _context()),
      );

      expect(result.dataOrNull, repository.currentSubscription);
      expect(repository.currentSubscriptionCompanyIds, ['company-1']);
    },
  );

  test('current subscription use case blocks non-owner roles', () async {
    final repository = _FakeSubscriptionsRepository();
    final useCase = GetCurrentCompanySubscriptionUseCase(repository);

    final result = await useCase(
      GetCurrentCompanySubscriptionParams(
        currentCompanyContext: _context(role: CompanyRole.accountant),
      ),
    );

    expect(result.failureOrNull, isA<PermissionFailure>());
    expect(
      result.failureOrNull?.code,
      FailureCodes.permissionSubscriptionsView,
    );
    expect(repository.currentSubscriptionCompanyIds, isEmpty);
  });
}

CurrentCompanyContext _context({CompanyRole role = CompanyRole.owner}) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: role,
  );
}

final class _FakeSubscriptionsRepository implements SubscriptionsRepository {
  final plans = const [
    SubscriptionPlan(
      id: 'plan-basic',
      code: 'basic',
      name: 'Basic',
      monthlyPrice: 100,
      maxUsers: PlanLimit(5),
      maxVehicles: PlanLimit(10),
      maxTripsPerMonth: PlanLimit(100),
      hasDriverApp: true,
      hasAdvancedReports: false,
      hasDocumentUpload: false,
      hasMaintenance: false,
      hasWhatsappNotifications: false,
      isActive: true,
    ),
  ];

  late final currentSubscription = CompanySubscription(
    id: 'subscription-1',
    companyId: 'company-1',
    planId: 'plan-basic',
    status: SubscriptionStatus.active,
    plan: plans.single,
  );

  int availablePlansCalls = 0;
  final currentSubscriptionCompanyIds = <String>[];

  @override
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    availablePlansCalls += 1;
    return Success(plans);
  }

  @override
  Future<Result<CompanySubscription?>> getCurrentCompanySubscription({
    required String companyId,
  }) async {
    currentSubscriptionCompanyIds.add(companyId);
    return Success(currentSubscription);
  }
}
