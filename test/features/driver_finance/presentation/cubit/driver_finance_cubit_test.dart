import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
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
import 'package:horus_system/features/driver_finance/presentation/cubit/driver_finance_cubit.dart';
import 'package:horus_system/features/driver_finance/presentation/cubit/driver_finance_state.dart';
import 'package:horus_system/features/drivers/domain/entities/driver.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_file.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_image_urls.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_status.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_write_data.dart';
import 'package:horus_system/features/drivers/domain/repositories/drivers_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/get_drivers_usecase.dart';
import 'package:test/test.dart';

void main() {
  group('DriverFinanceCubit', () {
    test('loads drivers and derives management permission from Domain policy', () async {
      final cubit = _createCubit(
        financeRepository: _FakeDriverFinanceRepository(),
        balanceRepository: _FakeDriverBalanceRepository([_balance(-5600)]),
      );
      addTearDown(cubit.close);

      await cubit.load(_context);

      final state = cubit.state as DriverFinanceLoaded;
      expect(state.drivers, [_driver]);
      expect(state.canManage, isTrue);
      expect(state.selectedDriverId, isNull);
    });

    test('loads movements, trip options, and canonical balance for selection', () async {
      final financeRepository = _FakeDriverFinanceRepository(
        movements: [_advance(id: 'movement-1', amount: 500)],
      );
      final balanceRepository = _FakeDriverBalanceRepository([
        _balance(-5600),
      ]);
      final provider = _FakeCompanyBusinessDateProvider(
        BusinessDate(year: 2026, month: 9, day: 19),
      );
      final cubit = _createCubit(
        financeRepository: financeRepository,
        balanceRepository: balanceRepository,
        businessDateProvider: provider,
      );
      addTearDown(cubit.close);

      await cubit.load(_context);
      await cubit.selectDriver(_driverId);

      final state = cubit.state as DriverFinanceLoaded;
      expect(state.selectedDriverId, _driverId);
      expect(state.movements, hasLength(1));
      expect(state.balance?.netBalance, -5600);
      expect(financeRepository.lastTripOptionsTimeZoneId, _timeZoneId);
      expect(
        balanceRepository.beforeExclusiveBoundaries.single,
        BusinessDate(year: 2026, month: 9, day: 20),
      );
      expect(provider.lastCompanyId, _companyId);
    });

    test('re-fetches finance details after a successful movement', () async {
      final financeRepository = _FakeDriverFinanceRepository(
        movements: [_advance(id: 'movement-1', amount: 500)],
        addedMovement: _advance(id: 'movement-2', amount: 100),
      );
      final balanceRepository = _FakeDriverBalanceRepository([
        _balance(-5600),
        _balance(-5700),
      ]);
      final cubit = _createCubit(
        financeRepository: financeRepository,
        balanceRepository: balanceRepository,
      );
      addTearDown(cubit.close);

      await cubit.load(_context);
      await cubit.selectDriver(_driverId);
      await cubit.addDriverAdvance(
        amount: '100.00',
        movementDate: BusinessDate(year: 2026, month: 9, day: 19),
      );

      final state = cubit.state as DriverFinanceLoaded;
      expect(state.movements.first.id, 'movement-2');
      expect(state.balance?.netBalance, -5700);
      expect(financeRepository.addMovementCalls, 1);
      expect(financeRepository.lastWriteData?.amount.minorUnits, 10000);
      expect(financeRepository.lastWriteData?.amount.currency.value, 'AED');
      expect(balanceRepository.calls, 2);
    });

    test('returns the trusted company Business Date for movement forms', () async {
      final businessDate = BusinessDate(year: 2026, month: 9, day: 19);
      final provider = _FakeCompanyBusinessDateProvider(businessDate);
      final cubit = _createCubit(
        financeRepository: _FakeDriverFinanceRepository(),
        balanceRepository: _FakeDriverBalanceRepository([_balance(0)]),
        businessDateProvider: provider,
      );
      addTearDown(cubit.close);

      await cubit.load(_context);
      final result = await cubit.getCurrentBusinessDate();

      expect(result.dataOrNull, businessDate);
      expect(provider.lastCompanyId, _companyId);
    });
  });
}

const _companyId = 'company-test';
const _driverId = 'driver-test';
const _timeZoneId = 'Asia/Dubai';

const _context = CurrentCompanyContext(
  company: Company(
    id: _companyId,
    name: 'Test Company',
    businessTimezone: _timeZoneId,
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  role: CompanyRole.accountant,
);

const _driver = Driver(
  id: _driverId,
  companyId: _companyId,
  fullName: 'Test Driver',
  status: DriverStatus.active,
);

DriverFinanceCubit _createCubit({
  required _FakeDriverFinanceRepository financeRepository,
  required _FakeDriverBalanceRepository balanceRepository,
  _FakeCompanyBusinessDateProvider? businessDateProvider,
}) {
  final provider =
      businessDateProvider ??
      _FakeCompanyBusinessDateProvider(
        BusinessDate(year: 2026, month: 9, day: 19),
      );
  final businessDateUseCase = GetCompanyBusinessDateUseCase(provider);

  return DriverFinanceCubit(
    getDriversUseCase: GetDriversUseCase(_FakeDriversRepository()),
    getCompanyBusinessDateUseCase: businessDateUseCase,
    getDriverMovementsUseCase: GetDriverMovementsUseCase(financeRepository),
    getDriverTripOptionsUseCase: GetDriverTripOptionsUseCase(financeRepository),
    addDriverAdvanceUseCase: AddDriverAdvanceUseCase(financeRepository),
    addDriverChargeUseCase: AddDriverChargeUseCase(financeRepository),
    addDriverCashReturnUseCase: AddDriverCashReturnUseCase(financeRepository),
    getCurrentCanonicalDriverBalanceUseCase:
        GetCurrentCanonicalDriverBalanceUseCase(
          getCompanyBusinessDateUseCase: businessDateUseCase,
          getCanonicalDriverBalanceUseCase: GetCanonicalDriverBalanceUseCase(
            balanceRepository,
          ),
        ),
  );
}

DriverBalance _balance(double closingBalance) {
  return DriverBalance(
    companyId: _companyId,
    driverId: _driverId,
    checkpoint: DriverBalanceCheckpoint(
      settlementId: 'settlement-test',
      periodEnd: BusinessDate(year: 2026, month: 8, day: 31),
      snapshotCreatedAt: DateTime.utc(2026, 9, 1),
      closingBalance: closingBalance,
    ),
    totalAdvances: 0,
    totalDriverCharges: 0,
  );
}

DriverFinancialMovement _advance({
  required String id,
  required double amount,
}) {
  return DriverFinancialMovement(
    id: id,
    companyId: _companyId,
    driverId: _driverId,
    type: DriverFinancialMovementType.advance,
    amount: amount,
    movementDate: BusinessDate(year: 2026, month: 9, day: 1),
  );
}

final class _FakeDriversRepository implements DriversRepository {
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
    return const Success(DriverImageUrls.empty);
  }
}

final class _FakeDriverFinanceRepository implements DriverFinanceRepository {
  final List<DriverFinancialMovement> movements;
  final DriverFinancialMovement? addedMovement;
  int addMovementCalls = 0;
  String? lastTripOptionsTimeZoneId;
  DriverFinancialMovementWriteData? lastWriteData;

  _FakeDriverFinanceRepository({
    List<DriverFinancialMovement>? movements,
    this.addedMovement,
  }) : movements = [...?movements];

  @override
  Future<Result<List<DriverFinancialMovement>>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) async {
    return Success(List.unmodifiable(movements));
  }

  @override
  Future<Result<List<DriverFinanceTripOption>>> getDriverTripOptions({
    required String companyId,
    required String driverId,
    required String timeZoneId,
  }) async {
    lastTripOptionsTimeZoneId = timeZoneId;
    return const Success<List<DriverFinanceTripOption>>([]);
  }

  @override
  Future<Result<DriverFinancialMovement>> addDriverMovement({
    required DriverFinancialMovementWriteData data,
    required String actorRole,
  }) async {
    addMovementCalls++;
    lastWriteData = data;
    final movement = addedMovement;
    if (movement == null) throw StateError('No test movement configured.');
    movements.insert(0, movement);
    return Success(movement);
  }
}

final class _FakeDriverBalanceRepository implements DriverBalanceRepository {
  final List<DriverBalance> balances;
  final List<BusinessDate> beforeExclusiveBoundaries = [];
  int calls = 0;

  _FakeDriverBalanceRepository(this.balances);

  @override
  Future<Result<DriverBalance>> getCanonicalDriverBalance({
    required String companyId,
    required String driverId,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    beforeExclusiveBoundaries.add(beforeExclusive);
    return Success(balances[calls++]);
  }
}

final class _FakeCompanyBusinessDateProvider
    implements CompanyBusinessDateProvider {
  final BusinessDate businessDate;
  String? lastCompanyId;

  _FakeCompanyBusinessDateProvider(this.businessDate);

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    lastCompanyId = companyId;
    return Success(businessDate);
  }
}
