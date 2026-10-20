import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
import 'package:horus_system/core/realtime/domain/entities/company_invalidation_resource.dart';
import 'package:horus_system/core/realtime/domain/repositories/company_data_changes_repository.dart';
import 'package:horus_system/core/realtime/domain/usecases/watch_company_data_changes_usecase.dart';
import 'package:horus_system/core/realtime/presentation/cubit/company_realtime_cubit.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:test/test.dart';

void main() {
  test(
    'reacts to current-company events and rejects old session events',
    () async {
      final repository = _ControllableRepository();
      final cubit = CompanyRealtimeCubit(
        watchChanges: WatchCompanyDataChangesUseCase(repository),
      );
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      cubit.watchCompany('company-1');
      repository.addChange('company-1');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 1);
      expect(
        cubit.state.revisionFor(CompanyInvalidationResource.tripFormLookups),
        1,
      );

      cubit.watchCompany('company-2');
      repository.addChange('company-1');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 0);

      repository.addChange('company-2');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.companyId, 'company-2');
      expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 1);
    },
  );

  test('new session drops previously requested finance subscriptions', () async {
    final repository = _ControllableRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    cubit.watchCompany(
      'company-1',
      additionalResources: const {CompanyDataResource.tripExpenses},
    );
    expect(repository.additionalResourcesByCompany['company-1'], {
      CompanyDataResource.tripExpenses,
    });
    cubit.watchCompany('company-2');
    expect(repository.additionalResourcesByCompany['company-2'], isEmpty);
  });

  test('failed prior channel cleanup emits typed failure', () async {
    final repository = _FailingCancellationRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(cubit.close);

    cubit.watchCompany('company-1');
    cubit.watchCompany('company-2');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.companyId, 'company-2');
    expect(
      cubit.state.failure?.code,
      FailureCodes.realtimeSubscriptionUnavailable,
    );
  });

  test('logout disposal completes even if channel removal fails', () async {
    final repository = _FailingCancellationRepository(failAll: true);
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    cubit.watchCompany('company-1');
    await cubit.close();
    expect(cubit.isClosed, isTrue);
  });

  test('preserves revision across typed subscription failures', () async {
    final repository = _ControllableRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    cubit.watchCompany('company-1');
    repository.addChange('company-1');
    repository.addFailure('company-1');
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 1);
    expect(
      cubit.state.failure?.code,
      FailureCodes.realtimeSubscriptionUnavailable,
    );

    repository.addChange('company-1');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 2);
    expect(cubit.state.failure, isNull);
  });
  test('Drivers changes do not invalidate Customers', () async {
    final repository = _ControllableRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    cubit.watchCompany('company-1');
    repository.addChange('company-1', resource: CompanyDataResource.drivers);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.revisionFor(CompanyInvalidationResource.drivers), 1);
    expect(
      cubit.state.revisionFor(CompanyInvalidationResource.tripFormLookups),
      1,
    );
    expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 0);
  });
  test('Routes invalidates list, joined Trip names and form lookups', () async {
    final repository = _ControllableRepository();
    final cubit = CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
    addTearDown(() async {
      await cubit.close();
      await repository.close();
    });

    cubit.watchCompany('company-1');
    repository.addChange('company-1', resource: CompanyDataResource.routes);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.revisionFor(CompanyInvalidationResource.routes), 1);
    expect(cubit.state.revisionFor(CompanyInvalidationResource.trips), 1);
    expect(
      cubit.state.revisionFor(CompanyInvalidationResource.tripFormLookups),
      1,
    );
    expect(cubit.state.revisionFor(CompanyInvalidationResource.payments), 0);
  });

  test(
    'Fleet only invalidates its selected and derived read projections',
    () async {
      final repository = _ControllableRepository();
      final cubit = CompanyRealtimeCubit(
        watchChanges: WatchCompanyDataChangesUseCase(repository),
      );
      addTearDown(() async {
        await cubit.close();
        await repository.close();
      });

      cubit.watchCompany('company-1');
      repository.addChange('company-1', resource: CompanyDataResource.fleet);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.revisionFor(CompanyInvalidationResource.fleet), 1);
      expect(
        cubit.state.revisionFor(CompanyInvalidationResource.tripFormLookups),
        1,
      );
      expect(cubit.state.revisionFor(CompanyInvalidationResource.customers), 0);
      expect(cubit.state.revisionFor(CompanyInvalidationResource.drivers), 0);
      expect(
        cubit.state.revisionFor(
          CompanyInvalidationResource.fleetLicenseDocuments,
        ),
        0,
      );
    },
  );
}

final class _ControllableRepository implements CompanyDataChangesRepository {
  final Map<String, StreamController<Result<CompanyDataChange>>> controllers =
      {};
  final Map<String, Set<CompanyDataResource>> additionalResourcesByCompany =
      {};

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    additionalResourcesByCompany[companyId] = additionalResources;
    final controller = StreamController<Result<CompanyDataChange>>.broadcast(
      sync: true,
    );
    controllers[companyId] = controller;
    return controller.stream;
  }

  void addChange(
    String companyId, {
    CompanyDataResource resource = CompanyDataResource.customers,
  }) => controllers[companyId]!.add(
    Success(CompanyDataChange(companyId: companyId, resource: resource)),
  );

  void addFailure(String companyId) => controllers[companyId]!.add(
    const FailureResult(
      NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
    ),
  );

  Future<void> close() async {
    for (final controller in controllers.values) {
      await controller.close();
    }
  }
}

final class _FailingCancellationRepository
    implements CompanyDataChangesRepository {
  final bool failAll;

  const _FailingCancellationRepository({this.failAll = false});

  @override
  Stream<Result<CompanyDataChange>> watchChanges({
    required String companyId,
    Set<CompanyDataResource> additionalResources = const {},
  }) {
    final controller = StreamController<Result<CompanyDataChange>>(
      onCancel: () async {
        if (failAll || companyId == 'company-1') {
          throw StateError('simulated unsubscribe failure');
        }
      },
    );
    return controller.stream;
  }
}
