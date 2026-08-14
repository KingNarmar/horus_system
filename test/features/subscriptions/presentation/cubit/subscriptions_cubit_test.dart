import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_subscription.dart';
import 'package:horus_system/features/subscriptions/domain/entities/plan_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/subscription_plan.dart';
import 'package:horus_system/features/subscriptions/domain/repositories/subscriptions_repository.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_available_subscription_plans_usecase.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_current_company_subscription_usecase.dart';
import 'package:horus_system/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:horus_system/features/subscriptions/presentation/cubit/subscriptions_state.dart';
import 'package:test/test.dart';

void main() {
  test(
    'load emits loaded state for owner with plans and no current subscription',
    () async {
      final repository = _FakeSubscriptionsRepository();
      final cubit = _cubit(repository);

      await cubit.load(_context());
      final state = cubit.state as SubscriptionsLoaded;

      expect(state.plans.single.code, 'basic');
      expect(state.currentSubscription, isNull);
      expect(state.hasCurrentSubscription, isFalse);
      await cubit.close();
    },
  );

  test('load emits failure for non-owner role', () async {
    final repository = _FakeSubscriptionsRepository();
    final cubit = _cubit(repository);

    await cubit.load(_context(role: CompanyRole.admin));
    final state = cubit.state as SubscriptionsFailure;

    expect(state.failure.code, FailureCodes.permissionSubscriptionsView);
    expect(repository.availablePlansCalls, 0);
    await cubit.close();
  });
}

SubscriptionsCubit _cubit(_FakeSubscriptionsRepository repository) {
  return SubscriptionsCubit(
    getAvailablePlansUseCase: GetAvailableSubscriptionPlansUseCase(repository),
    getCurrentSubscriptionUseCase: GetCurrentCompanySubscriptionUseCase(
      repository,
    ),
  );
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
      maxVehicles: PlanLimit(20),
      maxTripsPerMonth: PlanLimit(500),
      hasDriverApp: true,
      hasAdvancedReports: false,
      hasDocumentUpload: false,
      hasMaintenance: false,
      hasWhatsappNotifications: false,
      isActive: true,
    ),
  ];

  int availablePlansCalls = 0;

  @override
  Future<Result<List<SubscriptionPlan>>> getAvailablePlans() async {
    availablePlansCalls += 1;
    return Success(plans);
  }

  @override
  Future<Result<CompanySubscription?>> getCurrentCompanySubscription({
    required String companyId,
  }) async {
    return const Success(null);
  }
}
