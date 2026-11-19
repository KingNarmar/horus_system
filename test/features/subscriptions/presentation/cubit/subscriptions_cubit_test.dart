import 'dart:async';

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
  test(
    'owner and admin load one server-authoritative usage projection',
    () async {
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
    },
  );

  test('viewer never queries company usage', () async {
    final repository = _FakeCompanyQuotaRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context(role: CompanyRole.viewer));

    final state = cubit.state as SubscriptionsFailure;
    expect(state.failure.code, QuotaFailureCodes.permissionDenied);
    expect(repository.callCount, 0);
  });

  test(
    'switching companies drops late results from the previous tenant',
    () async {
      final repository = _DeferredQuotaRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      final loadA = cubit.load(_context(companyId: 'company-a'));
      final loadB = cubit.load(_context(companyId: 'company-b'));
      await repository.resolve(1, companyId: 'company-b');
      await loadB;
      expect(
        (cubit.state as SubscriptionsLoaded).currentCompanyContext.companyId,
        'company-b',
      );
      await repository.resolve(0, companyId: 'company-a');
      await loadA;
      expect(
        (cubit.state as SubscriptionsLoaded).quota.entitlement.companyId,
        'company-b',
      );
    },
  );

  test(
    'refresh labels the old snapshot and replaces it from the server',
    () async {
      final repository = _DeferredQuotaRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      final company = _context();

      final first = cubit.load(company);
      await repository.resolve(0, companyId: company.companyId);
      await first;
      final refreshing = cubit.refresh(company);
      expect((cubit.state as SubscriptionsLoaded).isRefreshing, isTrue);
      expect(repository.pending.length, 2);
      await repository.resolve(1, companyId: company.companyId);
      await refreshing;
      expect((cubit.state as SubscriptionsLoaded).isRefreshing, isFalse);
    },
  );

  test(
    'failed refresh removes the stale snapshot rather than presenting it as current',
    () async {
      final repository = _DeferredQuotaRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);
      final company = _context();

      final first = cubit.load(company);
      await repository.resolve(0, companyId: company.companyId);
      await first;
      final refreshing = cubit.refresh(company);
      repository.pending[1].complete(
        const FailureResult(ServerFailure(code: QuotaFailureCodes.unavailable)),
      );
      await refreshing;
      expect(cubit.state, isA<SubscriptionsFailure>());
    },
  );

  test('concurrent invalidations coalesce into a final server read', () async {
    final repository = _DeferredQuotaRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);
    final company = _context();

    final initial = cubit.load(company);
    await repository.resolve(0, companyId: company.companyId);
    await initial;

    final refreshing = cubit.refresh(company);
    await cubit.refresh(company);
    await cubit.refresh(company);
    expect(repository.pending.length, 2);

    await repository.resolve(1, companyId: company.companyId);
    await Future<void>.delayed(Duration.zero);
    expect(repository.pending.length, 3);
    expect((cubit.state as SubscriptionsLoaded).isRefreshing, isTrue);

    await repository.resolve(2, companyId: company.companyId);
    await refreshing;
    expect((cubit.state as SubscriptionsLoaded).isRefreshing, isFalse);
    expect(repository.pending.length, 3);
  });

  test('offline company switch never falls back to prior tenant usage', () async {
    final repository = _DeferredQuotaRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    final companyA = _context(companyId: 'company-a');
    final first = cubit.load(companyA);
    await repository.resolve(0, companyId: companyA.companyId);
    await first;
    expect(cubit.state, isA<SubscriptionsLoaded>());

    final companyB = _context(companyId: 'company-b');
    final second = cubit.load(companyB);
    expect(cubit.state, isA<SubscriptionsLoading>());
    repository.pending[1].complete(
      const FailureResult(
        NetworkFailure(code: QuotaFailureCodes.unavailable),
      ),
    );
    await second;
    expect(cubit.state, isA<SubscriptionsFailure>());
  });

  test('role revocation discards an in-flight authorized refresh', () async {
    final repository = _DeferredQuotaRepository();
    final cubit = _cubit(repository);
    addTearDown(cubit.close);
    final company = _context();
    final first = cubit.load(company);
    await repository.resolve(0, companyId: company.companyId);
    await first;

    final refreshing = cubit.refresh(company);
    final revoked = cubit.load(_context(role: CompanyRole.viewer));
    await revoked;
    expect(cubit.state, isA<SubscriptionsFailure>());
    await repository.resolve(1, companyId: company.companyId);
    await refreshing;
    expect(cubit.state, isA<SubscriptionsFailure>());
  });

  test(
    'unexpected foreign snapshot is rejected even from a fake repository',
    () async {
      final repository = _DeferredQuotaRepository();
      final cubit = _cubit(repository);
      addTearDown(cubit.close);

      final first = cubit.load(_context(companyId: 'company-a'));
      await repository.resolve(0, companyId: 'company-other');
      await first;
      expect(
        (cubit.state as SubscriptionsFailure).failure.code,
        QuotaFailureCodes.corrupt,
      );
    },
  );

  test('missing server projection never shows a permissive plan', () async {
    final repository = _FakeCompanyQuotaRepository(missing: true);
    final cubit = _cubit(repository);
    addTearDown(cubit.close);

    await cubit.load(_context());

    final state = cubit.state as SubscriptionsFailure;
    expect(state.failure.code, QuotaFailureCodes.unavailable);
  });
}

SubscriptionsCubit _cubit(CompanyQuotaRepository repository) {
  return SubscriptionsCubit(
    getCompanyQuotaUsageUseCase: GetCompanyQuotaUsageUseCase(repository),
  );
}

CurrentCompanyContext _context({
  CompanyRole role = CompanyRole.owner,
  String companyId = 'company-1',
}) {
  return CurrentCompanyContext(
    company: Company(id: companyId, name: 'Company One'),
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
          for (final resource in [
            EntitlementResource.customers,
            EntitlementResource.drivers,
            EntitlementResource.routes,
            EntitlementResource.lifetimeTrips,
            EntitlementResource.lifetimeInvoices,
            EntitlementResource.businessDocuments,
          ])
            resource: CompanyQuotaUsage(
              resource: resource,
              limit: entitlement.limitFor(resource),
              used: resource == EntitlementResource.drivers ? 7 : 1,
            ),
        },
      ),
    );
  }
}

final class _DeferredQuotaRepository implements CompanyQuotaRepository {
  final List<Completer<Result<CompanyQuotaSnapshot>>> pending = [];

  @override
  Future<Result<CompanyQuotaSnapshot>> getUsage({required String companyId}) {
    final completer = Completer<Result<CompanyQuotaSnapshot>>();
    pending.add(completer);
    return completer.future;
  }

  Future<void> resolve(int index, {required String companyId}) async {
    final result = await _FakeCompanyQuotaRepository().getUsage(
      companyId: companyId,
    );
    pending[index].complete(result);
  }
}
