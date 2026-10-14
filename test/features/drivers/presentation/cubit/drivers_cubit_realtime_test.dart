import 'dart:async';

import 'package:horus_system/core/domain/services/business_time_zone_converter.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/drivers/domain/entities/driver.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status_filter.dart';
import 'package:horus_system/features/drivers/domain/repositories/drivers_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/add_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/can_manage_drivers_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/deactivate_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_image_urls_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_drivers_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/reactivate_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/update_driver_usecase.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_cubit.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_state.dart';
import 'package:test/test.dart';

void main() {
  test('refresh preserves visible list, filters and latest authoritative rows', () async {
    final repository = _QueuedDriversRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final initialLoad = cubit.loadDrivers(_companyA);
    repository.complete(0, [_driver('driver-1', 'Alpha')]);
    await initialLoad;
    cubit.setSearchQuery('Bravo');
    cubit.setStatusFilter(DriverStatusFilter.all);

    final refresh = cubit.refreshDrivers(_companyA);
    final duplicateHint = cubit.refreshDrivers(_companyA);
    expect(repository.requestedCompanies, ['company-a', 'company-a']);
    expect(cubit.state, isA<DriversLoaded>());

    repository.complete(1, [_driver('driver-1', 'Alpha')]);
    await Future<void>.delayed(Duration.zero);
    expect(repository.requestedCompanies, [
      'company-a',
      'company-a',
      'company-a',
    ]);
    repository.complete(2, [_driver('driver-2', 'Bravo')]);
    await refresh;
    await duplicateHint;

    final state = cubit.state as DriversLoaded;
    expect(state.searchQuery, 'Bravo');
    expect(state.statusFilter, DriverStatusFilter.all);
    expect(state.allDrivers.single.id, 'driver-2');
    expect(state.drivers.single.fullName, 'Bravo');
  });

  test('late load from previous company cannot overwrite current company', () async {
    final repository = _QueuedDriversRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final oldLoad = cubit.loadDrivers(_companyA);
    final newLoad = cubit.loadDrivers(_companyB);
    repository.complete(1, [_driver('b-1', 'Beta', companyId: 'company-b')]);
    await newLoad;
    repository.complete(0, [_driver('a-1', 'Alpha')]);
    await oldLoad;

    final state = cubit.state as DriversLoaded;
    expect(state.currentCompanyContext.companyId, 'company-b');
    expect(state.allDrivers.single.companyId, 'company-b');
  });

  test('permission revocation hides previously loaded Drivers data', () async {
    final repository = _QueuedDriversRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final initial = cubit.loadDrivers(_companyA);
    repository.complete(0, [_driver('driver-1', 'Alpha')]);
    await initial;
    final refresh = cubit.refreshDrivers(_companyA);
    repository.completeResult(
      1,
      const FailureResult<List<Driver>>(
        PermissionFailure(code: FailureCodes.permissionDriversView),
      ),
    );
    await refresh;
    expect(cubit.state, isA<DriversFailure>());
  });

  test('temporary refresh error retains list with typed recoverable failure', () async {
    final repository = _QueuedDriversRepository();
    final cubit = _createCubit(repository);
    addTearDown(cubit.close);

    final initial = cubit.loadDrivers(_companyA);
    repository.complete(0, [_driver('driver-1', 'Alpha')]);
    await initial;
    final refresh = cubit.refreshDrivers(_companyA);
    repository.completeResult(
      1,
      const FailureResult<List<Driver>>(
        NetworkFailure(code: FailureCodes.realtimeSubscriptionUnavailable),
      ),
    );
    await refresh;

    final state = cubit.state as DriversLoaded;
    expect(state.allDrivers.single.id, 'driver-1');
    expect(
      state.refreshFailure?.code,
      FailureCodes.realtimeSubscriptionUnavailable,
    );
  });

  test('async load completing after Cubit disposal emits no state', () async {
    final repository = _QueuedDriversRepository();
    final cubit = _createCubit(repository);
    final request = cubit.loadDrivers(_companyA);
    await cubit.close();
    repository.complete(0, [_driver('driver-1', 'Alpha')]);
    await request;
    expect(cubit.isClosed, isTrue);
  });
}

const _companyA = CurrentCompanyContext(
  company: Company(id: 'company-a', name: 'A'),
  role: CompanyRole.owner,
);
const _companyB = CurrentCompanyContext(
  company: Company(id: 'company-b', name: 'B'),
  role: CompanyRole.owner,
);

Driver _driver(String id, String name, {String companyId = 'company-a'}) =>
    Driver(
      id: id,
      companyId: companyId,
      fullName: name,
      status: DriverStatus.active,
    );

DriversCubit _createCubit(_QueuedDriversRepository repository) => DriversCubit(
  getDriversUseCase: GetDriversUseCase(repository),
  canManageDriversUseCase: const CanManageDriversUseCase(),
  getDriverImageUrlsUseCase: GetDriverImageUrlsUseCase(repository),
  addDriverUseCase: AddDriverUseCase(repository),
  updateDriverUseCase: UpdateDriverUseCase(repository),
  deactivateDriverUseCase: DeactivateDriverUseCase(repository),
  reactivateDriverUseCase: ReactivateDriverUseCase(repository),
  getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(_UnusedAuditRepository()),
  convertInstantsToBusinessLocalDateTimesUseCase:
      ConvertInstantsToBusinessLocalDateTimesUseCase(_UnusedConverter()),
  getCompanyBusinessDateUseCase:
      GetCompanyBusinessDateUseCase(_UnusedDateProvider()),
);

final class _QueuedDriversRepository implements DriversRepository {
  final List<String> requestedCompanies = [];
  final List<Completer<Result<List<Driver>>>> _completions = [];

  @override
  Future<Result<List<Driver>>> getDrivers({required String companyId}) {
    requestedCompanies.add(companyId);
    final completer = Completer<Result<List<Driver>>>();
    _completions.add(completer);
    return completer.future;
  }

  void complete(int index, List<Driver> drivers) =>
      completeResult(index, Success(drivers));

  void completeResult(int index, Result<List<Driver>> result) =>
      _completions[index].complete(result);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedAuditRepository implements AuditLogRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedConverter implements BusinessTimeZoneConverter {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final class _UnusedDateProvider implements CompanyBusinessDateProvider {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
