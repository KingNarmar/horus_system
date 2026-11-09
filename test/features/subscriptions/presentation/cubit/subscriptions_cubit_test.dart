import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/subscriptions/domain/entities/company_entitlement.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_feature.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_limit.dart';
import 'package:horus_system/features/subscriptions/domain/entities/entitlement_resource.dart';
import 'package:horus_system/features/subscriptions/domain/failures/entitlement_failure_codes.dart';
import 'package:horus_system/features/subscriptions/domain/repositories/company_entitlements_repository.dart';
import 'package:horus_system/features/subscriptions/domain/usecases/get_company_entitlement_usecase.dart';
import 'package:horus_system/features/subscriptions/presentation/cubit/subscriptions_cubit.dart';
import 'package:horus_system/features/subscriptions/presentation/cubit/subscriptions_state.dart';
import 'package:test/test.dart';

void main() {
  test('owner and admin load the authoritative company grant', () async {
    for (final role in [CompanyRole.owner, CompanyRole.admin]) {
      final repository = _FakeCompanyEntitlementsRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      await cubit.load(_context(role: role));
      final state = cubit.state as SubscriptionsLoaded;

      expect(state.entitlement.planCode, 'free_starter');
      expect(state.entitlement.expiresAt, isNull);
      expect(repository.callCount, 1);
      expect(repository.lastCompanyId, 'company-1');
    }
  });

  test('viewer never queries the company entitlement', () async {
    final repository = _FakeCompanyEntitlementsRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context(role: CompanyRole.viewer));

    final state = cubit.state as SubscriptionsFailure;
    expect(state.failure.code, EntitlementFailureCodes.permissionDenied);
    expect(repository.callCount, 0);
  });

  test('missing server grant does not show a permissive plan', () async {
    final repository = _FakeCompanyEntitlementsRepository(missing: true);
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context());

    final state = cubit.state as SubscriptionsFailure;
    expect(state.failure.code, EntitlementFailureCodes.unavailable);
  });
}

SubscriptionsCubit _cubit(_FakeCompanyEntitlementsRepository repository) {
  return SubscriptionsCubit(
    getCompanyEntitlementUseCase: GetCompanyEntitlementUseCase(repository),
  );
}

CurrentCompanyContext _context({CompanyRole role = CompanyRole.owner}) {
  return CurrentCompanyContext(
    company: const Company(id: 'company-1', name: 'Company One'),
    role: role,
  );
}

final class _FakeCompanyEntitlementsRepository
    implements CompanyEntitlementsRepository {
  final bool missing;
  int callCount = 0;
  String? lastCompanyId;

  _FakeCompanyEntitlementsRepository({this.missing = false});

  @override
  Future<Result<CompanyEntitlement>> getCurrent({
    required String companyId,
  }) async {
    callCount += 1;
    lastCompanyId = companyId;
    if (missing) {
      return const FailureResult(
        ServerFailure(code: EntitlementFailureCodes.unavailable),
      );
    }
    return Success(
      CompanyEntitlement(
        companyId: companyId,
        planCode: 'free_starter',
        policyVersion: 1,
        revision: 1,
        effectiveAt: DateTime.utc(2026, 11, 9),
        status: CompanyEntitlementStatus.active,
        limits: {
          for (final resource in EntitlementResource.values)
            resource: EntitlementLimit.finite(1),
        },
        enabledFeatures: const {
          EntitlementFeature.invoicePdf,
          EntitlementFeature.reportPdf,
        },
      ),
    );
  }
}
