import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_entitlement.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_quota_snapshot.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_quota_usage.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_feature.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:horus_system/features/subscriptions/domain/failures/quota_failure_codes.dart';
import 'package:horus_system/features/subscriptions/domain/repositories/company_quota_repository.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_company_quota_usage_usecase.dart';
import 'package:horus_system/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:horus_system/features/subscriptions/presentation/cubit/subscriptions_state.dart';
import 'package:test/test.dart';

void main() {
  test('owner and admin load one server-authoritative usage projection', () async {
    for (final role in [CompanyRole.owner, CompanyRole.admin]) {
      final repository = _FakeCompanyQuotaRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.load(_context(role: role));
      final state = cubit.state as SubscriptionsLoaded;

      expect(state.entitlement.planCode, 'free_starter');
      expect(state.entitlement.expiresAt, isNull);
      expect(state.quota.usageFor(EntitlementResource.companyUsers).used, 4);
      expect(
        state.quota.usageFor(EntitlementResource.companyUsers).isOverLimit,
        isTrue,
      );
      expect(repository.callCount, 1);
      expect(repository.lastCompanyId, 'company-1');
    }
  });

  test('viewer never queries company usage', () async {
    final repository = _FakeCompanyQuotaRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context(role: CompanyRole.viewer));

    final state = cubit.state as SubscriptionsFailure;
    expect(state.failure.code, QuotaFailureCodes.permissionDenied);
    expect(repository.callCount, 0);
  });

  test('missing server projection never shows a permissive plan', () async {
    final repository = _FakeCompanyQuotaRepository(missing: true);
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context());

    final state = cubit.state as SubscriptionsFailure;
    expect(state.failure.code, QuotaFailureCodes.unavailable);
  });
}

SubscriptionsCubit _cubit(_FakeCompanyQuotaRepository repository) {
  return SubscriptionsCubit(
    getCompanyQuotaUsageUseCase: GetCompanyQuotaUsageUseCase(repository),
  );
}

CurrentCompanyContext _context({CompanyRole role = CompanyRole.owner}) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: role,
  );
}

final class _FakeCompanyQuotaRepository implements CompanyQuotaRepository {
  final bool missing;
  int callCount = 0;
  String? lastCompanyId;

  _FakeCompanyQuotaRepository({this.missing = false});

  @override
  Future<Result<CompanyQuotaSnapshot>> getUsage({
    required String companyId,
  }) async {
    callCount += 1;
    lastCompanyId = companyId;
    if (missing) {
      return const FailureResult(
        ServerFailure(code: QuotaFailureCodes.unavailable),
      );
    }

    final entitlement = CompanyEntitlement(
      companyId: companyId,
      planCode: 'free_starter',
      policyVersion: 1,
      revision: 1,
      effectiveAt: DateTime.utc(2026, 11, 9),
      status: CompanyEntitlementStatus.active,
      limits: {
        for (final resource in EntitlementResource.values)
          resource: EntitlementLimit.finite(
            resource == EntitlementResource.companyUsers ? 3 : 6,
          ),
      },
      enabledFeatures: const {
        EntitlementFeature.invoicePdf,
        EntitlementFeature.reportPdf,
      },
    );

    return Success(
      CompanyQuotaSnapshot(
        entitlement: entitlement,
        usage: {
          EntitlementResource.companyUsers: CompanyQuotaUsage(
            resource: EntitlementResource.companyUsers,
            limit: entitlement.limitFor(EntitlementResource.companyUsers),
            used: 4,
          ),
          EntitlementResource.combinedVehicles: CompanyQuotaUsage(
            resource: EntitlementResource.combinedVehicles,
            limit: entitlement.limitFor(EntitlementResource.combinedVehicles),
            used: 2,
          ),
        },
      ),
    );
  }
}
