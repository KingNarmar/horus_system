import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_finance_trip_option.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_write_data.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_balance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_finance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/driver_finance_usecases.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import 'package:horus_system/features/drivers/domain/entities/driver.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_file.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_urls.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:horus_system/features/drivers/domain/repositories/drivers_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/add_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/deactivate_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_driver_image_urls_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_drivers_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/reactivate_driver_usecase.dart';
import 'package:horus_system/features/drivers/domain/usecases/update_driver_usecase.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_cubit.dart';
import 'package:horus_system/features/drivers/presentation/cubit/drivers_state.dart';
import 'package:test/test.dart';

void main() {
  group('DriversCubit canonical driver balance', () {
    test(
      'uses canonical balance instead of recalculating movement history',
      () async {
        final balanceRepository = _FakeDriverBalanceRepository([
          _balance(-5600),
        ]);
        final financeRepository = _FakeDriverFinanceRepository(
          movements: [_advance(id: 'historical-advance', amount: 6500)],
        );
        final cubit = _createCubit(
          financeRepository: financeRepository,
          balanceRepository: balanceRepository,
        );
        addTearDown(cubit.close);

        await cubit.loadDrivers(_context);
        await cubit.loadDriverFinancialMovements(_driver);

        final state = cubit.state as DriversLoaded;
        expect(state.selectedDriverBalance?.netBalance, -5600);
        expect(state.selectedDriverFinancialMovements, hasLength(1));
        expect(financeRepository.getMovementsCalls, 1);
        expect(balanceRepository.calls, 1);
        expect(balanceRepository.checkpointBoundaries.single, isNull);
      },
    );

    test('re-fetches canonical balance after a successful movement', () async {
      final balanceRepository = _FakeDriverBalanceRepository([
        _balance(-5600),
        _balance(-5700),
      ]);
      final financeRepository = _FakeDriverFinanceRepository(
        movements: [_advance(id: 'historical-advance', amount: 6500)],
        addedMovement: _advance(id: 'new-advance', amount: 100),
      );
      final cubit = _createCubit(
        financeRepository: financeRepository,
        balanceRepository: balanceRepository,
      );
      addTearDown(cubit.close);

      await cubit.loadDrivers(_context);
      await cubit.loadDriverFinancialMovements(_driver);
      await cubit.addDriverAdvance(
        driver: _driver,
        amount: 100,
        movementDate: DateTime(2026, 7, 22),
      );

      final state = cubit.state as DriversLoaded;
      expect(state.selectedDriverBalance?.netBalance, -5700);
      expect(state.selectedDriverFinancialMovements.first.id, 'new-advance');
      expect(financeRepository.addMovementCalls, 1);
      expect(balanceRepository.calls, 2);
      expect(balanceRepository.checkpointBoundaries, everyElement(isNull));
    });

    test('keeps loaded state when driver update fails', () async {
      final driversRepository = _FakeDriversRepository(
        updateResult: const FailureResult<Driver>(
          ValidationFailure(code: FailureCodes.validationDriverImageTooLarge),
        ),
      );
      final cubit = _createCubit(
        driversRepository: driversRepository,
        financeRepository: _FakeDriverFinanceRepository(movements: const []),
        balanceRepository: _FakeDriverBalanceRepository([]),
      );
      addTearDown(cubit.close);

      await cubit.loadDrivers(_ownerContext);
      final failure = await cubit.updateDriver(
        driver: _driver,
        fullName: _driver.fullName,
      );

      expect(failure?.code, FailureCodes.validationDriverImageTooLarge);
      expect(cubit.state, isA<DriversLoaded>());
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

const _context = CurrentCompanyContext(
  company: Company(id: _companyId, name: 'Company'),
  role: CompanyRole.accountant,
);

const _ownerContext = CurrentCompanyContext(
  company: Company(id: _companyId, name: 'Company'),
  role: CompanyRole.owner,
);

const _driver = Driver(
  id: _driverId,
  companyId: _companyId,
  fullName: 'Driver',
  status: DriverStatus.active,
);

DriversCubit _createCubit({
  _FakeDriversRepository? driversRepository,
  required _FakeDriverFinanceRepository financeRepository,
  required _FakeDriverBalanceRepository balanceRepository,
}) {
  final repository = driversRepository ?? _FakeDriversRepository();
  return DriversCubit(
    getDriversUseCase: GetDriversUseCase(repository),
    getDriverImageUrlsUseCase: GetDriverImageUrlsUseCase(repository),
    addDriverUseCase: AddDriverUseCase(repository),
    updateDriverUseCase: UpdateDriverUseCase(repository),
    deactivateDriverUseCase: DeactivateDriverUseCase(repository),
    reactivateDriverUseCase: ReactivateDriverUseCase(repository),
    getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
      _FakeAuditLogRepository(),
    ),
    getDriverMovementsUseCase: GetDriverMovementsUseCase(financeRepository),
    getDriverTripOptionsUseCase: GetDriverTripOptionsUseCase(financeRepository),
    addDriverAdvanceUseCase: AddDriverAdvanceUseCase(financeRepository),
    addDriverChargeUseCase: AddDriverChargeUseCase(financeRepository),
    addDriverCashReturnUseCase: AddDriverCashReturnUseCase(financeRepository),
    getCanonicalDriverBalanceUseCase: GetCanonicalDriverBalanceUseCase(
      balanceRepository,
    ),
  );
}

DriverBalance _balance(double closingBalance) {
  return DriverBalance(
    companyId: _companyId,
    driverId: _driverId,
    checkpoint: DriverBalanceCheckpoint(
      settlementId: 'settlement-1',
      periodEnd: DateTime(2026, 8, 31),
      snapshotCreatedAt: DateTime.utc(2026, 7, 15, 4, 59),
      closingBalance: closingBalance,
    ),
    totalAdvances: 0,
    totalDriverCharges: 0,
  );
}

DriverFinancialMovement _advance({required String id, required double amount}) {
  return DriverFinancialMovement(
    id: id,
    companyId: _companyId,
    driverId: _driverId,
    type: DriverFinancialMovementType.advance,
    amount: amount,
    movementDate: DateTime(2026, 7, 1),
  );
}

class _FakeDriversRepository implements DriversRepository {
  final Result<Driver>? updateResult;

  const _FakeDriversRepository({this.updateResult});

  @override
  Future<Result<List<Driver>>> getDrivers({required String companyId}) async {
    return const Success<List<Driver>>([_driver]);
  }

  @override
  Future<Result<Driver>> addDriver({
    required DriverWriteData data,
    required String actorRole,
    DriverImageUploadSet? imageUploads,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Driver>> updateDriver({
    required String driverId,
    required DriverWriteData data,
    required String actorRole,
    DriverImageUploadSet? imageUploads,
  }) {
    final result = updateResult;
    if (result != null) return Future.value(result);
    throw UnimplementedError();
  }

  @override
  Future<Result<Driver>> deactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<Driver>> reactivateDriver({
    required String companyId,
    required String driverId,
    required String actorRole,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<Result<DriverImageUrls>> getDriverImageUrls({
    required Driver driver,
  }) async {
    return const Success<DriverImageUrls>(DriverImageUrls.empty);
  }
}

class _FakeDriverFinanceRepository implements DriverFinanceRepository {
  final List<DriverFinancialMovement> movements;
  final DriverFinancialMovement? addedMovement;
  int getMovementsCalls = 0;
  int addMovementCalls = 0;

  _FakeDriverFinanceRepository({required this.movements, this.addedMovement});

  @override
  Future<Result<List<DriverFinancialMovement>>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) async {
    getMovementsCalls++;
    return Success<List<DriverFinancialMovement>>(movements);
  }

  @override
  Future<Result<List<DriverFinanceTripOption>>> getDriverTripOptions({
    required String companyId,
    required String driverId,
  }) async {
    return const Success<List<DriverFinanceTripOption>>([]);
  }

  @override
  Future<Result<DriverFinancialMovement>> addDriverMovement({
    required DriverFinancialMovementWriteData data,
    required String actorRole,
  }) async {
    addMovementCalls++;
    final movement = addedMovement;
    if (movement == null) throw StateError('No added movement configured.');
    return Success<DriverFinancialMovement>(movement);
  }
}

class _FakeDriverBalanceRepository implements DriverBalanceRepository {
  final List<DriverBalance> balances;
  final List<DateTime?> checkpointBoundaries = [];
  int calls = 0;

  _FakeDriverBalanceRepository(this.balances);

  @override
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required DateTime beforeExclusive,
    DateTime? checkpointBeforeExclusive,
  }) async {
    checkpointBoundaries.add(checkpointBeforeExclusive);
    final index = calls++;
    return Success<DriverBalance>(balances[index]);
  }
}

class _FakeAuditLogRepository implements AuditLogRepository {
  @override
  Future<Result<void>> createAuditLog({required AuditLogWriteData data}) async {
    return const Success<void>(null);
  }

  @override
  Future<Result<List<AuditLog>>> getEntityAuditLogs({
    required String companyId,
    required AuditModule module,
    required AuditEntityType entityType,
    required String entityId,
  }) async {
    return const Success<List<AuditLog>>([]);
  }
}
