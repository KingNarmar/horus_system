import 'dart:async';

import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/realtime/domain/entities/company_data_change.dart';
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
      expect(cubit.state.customersRevision, 1);

      cubit.watchCompany('company-2');
      repository.addChange('company-1');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.customersRevision, 0);

      repository.addChange('company-2');
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.companyId, 'company-2');
      expect(cubit.state.customersRevision, 1);
    },
  );

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

    expect(cubit.state.customersRevision, 1);
    expect(
      cubit.state.failure?.code,
      FailureCodes.realtimeSubscriptionUnavailable,
    );

    repository.addChange('company-1');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.customersRevision, 2);
    expect(cubit.state.failure, isNull);
  });
}

final class _ControllableRepository implements CompanyDataChangesRepository {
  final Map<String, StreamController<Result<CompanyDataChange>>> controllers =
      {};

  @override
  Stream<Result<CompanyDataChange>> watchChanges({required String companyId}) {
    final controller = StreamController<Result<CompanyDataChange>>.broadcast(
      sync: true,
    );
    controllers[companyId] = controller;
    return controller.stream;
  }

  void addChange(String companyId) => controllers[companyId]!.add(
    Success(
      CompanyDataChange(
        companyId: companyId,
        resource: CompanyDataResource.customers,
      ),
    ),
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
