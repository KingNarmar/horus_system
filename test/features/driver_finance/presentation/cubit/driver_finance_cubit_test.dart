import 'dart:async';

import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/errors/common_failures.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/usecases/get_company_business_date_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_activity_entry.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_balance_checkpoint.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_finance_trip_option.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_type.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_financial_movement_write_data.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_balance_activity_repository.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_finance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/can_manage_driver_finance_usecase.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/driver_finance_usecases.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_driver_balance_activity_usecase.dart';
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
    test(
      'loads drivers and derives management permission from Domain policy',
      () async {
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
      },
    );

    test(
      'loads movements, trip options, and canonical balance for selection',
      () async {
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
        expect(state.activity?.entries, hasLength(1));
        expect(state.activity?.canonicalBalance.netBalance.minorUnits, -560000);
        expect(financeRepository.lastTripOptionsTimeZoneId, _timeZoneId);
        expect(
          balanceRepository.beforeExclusiveBoundaries.single,
          BusinessDate(year: 2026, month: 9, day: 20),
        );
        expect(provider.lastCompanyId, _companyId);
      },
    );

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
      expect(state.activity?.entries.first.sourceId, 'movement-2');
      expect(state.activity?.canonicalBalance.netBalance.minorUnits, -570000);
      expect(financeRepository.addMovementCalls, 1);
      expect(financeRepository.lastWriteData?.amount.minorUnits, 10000);
      expect(financeRepository.lastWriteData?.amount.currency.value, 'AED');
      expect(balanceRepository.calls, 2);
    });

    test(
      'realtime silently replaces selected driver with canonical data',
      () async {
        final repository = _FakeDriverFinanceRepository(
          movements: [_advance(id: 'movement-1', amount: 100)],
        );
        final balances = _FakeDriverBalanceRepository([
          _balance(-5600),
          _balance(-5700),
        ]);
        final cubit = _createCubit(
          financeRepository: repository,
          balanceRepository: balances,
        );
        addTearDown(cubit.close);

        await cubit.load(_context);
        await cubit.selectDriver(_driverId);
        final emitted = <DriverFinanceState>[];
        final sub = cubit.stream.listen(emitted.add);
        addTearDown(sub.cancel);
        repository.movements.insert(0, _advance(id: 'movement-2', amount: 200));

        await cubit.refreshDriverFinanceFromRealtime();

        final latest = cubit.state as DriverFinanceLoaded;
        expect(latest.selectedDriverId, _driverId);
        expect(
          latest.activity?.entries
              .map((movement) => movement.sourceId)
              .toList(),
          ['movement-2', 'movement-1'],
        );
        expect(
          latest.activity?.canonicalBalance.netBalance.minorUnits,
          -570000,
        );
        expect(emitted.whereType<DriverFinanceLoading>(), isEmpty);
        expect(balances.calls, 2);
      },
    );

    test(
      'reconnect preserves the selected driver and reloads missed changes',
      () async {
        final repository = _FakeDriverFinanceRepository(
          movements: [_advance(id: 'movement-1', amount: 100)],
        );
        final cubit = _createCubit(
          financeRepository: repository,
          balanceRepository: _FakeDriverBalanceRepository([
            _balance(-5600),
            _balance(-5700),
          ]),
        );
        addTearDown(cubit.close);

        await cubit.load(_context);
        await cubit.selectDriver(_driverId);
        repository.movements.insert(0, _advance(id: 'movement-2', amount: 200));

        await cubit.reconcileDriverFinanceAfterReconnect(_context);

        final latest = cubit.state as DriverFinanceLoaded;
        expect(latest.selectedDriverId, _driverId);
        expect(latest.activity?.entries, hasLength(2));
        expect(
          latest.activity?.canonicalBalance.netBalance.minorUnits,
          -570000,
        );
      },
    );

    test(
      'expense invalidation refreshes a single driver-funded trip activity',
      () async {
        final financeRepository = _FakeDriverFinanceRepository();
        final balanceRepository = _FakeDriverBalanceRepository([
          _balance(-5600),
          _balance(-5590),
        ]);
        final cubit = _createCubit(
          financeRepository: financeRepository,
          balanceRepository: balanceRepository,
        );
        addTearDown(cubit.close);
        await cubit.load(_context);
        await cubit.selectDriver(_driverId);

        financeRepository.expenseEntries.add(
          DriverBalanceActivityEntry(
            source: DriverBalanceActivitySource.tripExpense,
            sourceId: 'expense-1',
            kind: DriverBalanceActivityKind.driverPaidTripExpense,
            companyId: _companyId,
            driverId: _driverId,
            tripId: 'trip-1',
            businessDate: BusinessDate(year: 2026, month: 9, day: 19),
            createdAt: DateTime.utc(2026, 9, 19),
            amount: Money(
              minorUnits: 1000,
              currency: CurrencyCode.tryParse('AED')!,
            ),
          ),
        );
        await cubit.refreshDriverFinanceFromRealtime();

        final latest = cubit.state as DriverFinanceLoaded;
        expect(latest.selectedDriverId, _driverId);
        expect(latest.activity?.entries, hasLength(1));
        expect(
          latest.activity?.entries.single.stableId,
          'tripExpense:expense-1',
        );
        expect(latest.activity?.entries.single.balanceImpact.minorUnits, 1000);
        expect(
          latest.activity?.canonicalBalance.netBalance.minorUnits,
          -559000,
        );
        expect(balanceRepository.calls, 2);
      },
    );

    test(
      'transient realtime error keeps selected balances and form failures',
      () async {
        final financeRepository = _FakeDriverFinanceRepository(
          movements: [_advance(id: 'movement-1', amount: 100)],
        );
        final cubit = _createCubit(
          financeRepository: financeRepository,
          balanceRepository: _FakeDriverBalanceRepository([
            _balance(-5600),
            _balance(-5700),
          ]),
        );
        addTearDown(cubit.close);

        await cubit.load(_context);
        await cubit.selectDriver(_driverId);
        financeRepository.movementsFailure = const UnexpectedFailure();
        await cubit.refreshDriverFinanceFromRealtime();

        final failed = cubit.state as DriverFinanceLoaded;
        expect(failed.activity?.entries.single.sourceId, 'movement-1');
        expect(
          failed.activity?.canonicalBalance.netBalance.minorUnits,
          -560000,
        );
        expect(failed.failure, isNull);
        expect(failed.realtimeRefreshFailure?.code, 'unexpected_error');

        financeRepository.movementsFailure = null;
        await cubit.refreshDriverFinanceFromRealtime();
        final recovered = cubit.state as DriverFinanceLoaded;
        expect(recovered.realtimeRefreshFailure, isNull);
        expect(
          recovered.activity?.canonicalBalance.netBalance.minorUnits,
          -570000,
        );
      },
    );

    test(
      'late realtime reply cannot restore a driver cleared during refresh',
      () async {
        final financeRepository = _FakeDriverFinanceRepository(
          movements: [_advance(id: 'movement-1', amount: 100)],
        );
        final cubit = _createCubit(
          financeRepository: financeRepository,
          balanceRepository: _FakeDriverBalanceRepository([_balance(-5600)]),
        );
        addTearDown(cubit.close);

        await cubit.load(_context);
        await cubit.selectDriver(_driverId);
        final barrier = Completer<void>();
        financeRepository.movementsBarrier = barrier;

        final refresh = cubit.refreshDriverFinanceFromRealtime();
        await cubit.selectDriver(null);
        barrier.complete();
        await refresh;

        final latest = cubit.state as DriverFinanceLoaded;
        expect(latest.selectedDriverId, isNull);
        expect(latest.activity, isNull);

        expect(latest.tripOptions, isEmpty);
      },
    );

    test(
      'remote Driver removal during save defers reference refresh',
      () async {
        final mutationBarrier = Completer<void>();
        final driversRepository = _FakeDriversRepository();
        final financeRepository = _FakeDriverFinanceRepository(
          movements: [_advance(id: 'movement-1', amount: 100)],
          addedMovement: _advance(id: 'movement-2', amount: 200),
          mutationBarrier: mutationBarrier,
        );
        final cubit = _createCubit(
          financeRepository: financeRepository,
          balanceRepository: _FakeDriverBalanceRepository([
            _balance(-5600),
            _balance(-5700),
          ]),
          driversRepository: driversRepository,
        );
        addTearDown(cubit.close);

        await cubit.load(_context);
        await cubit.selectDriver(_driverId);
        final pendingSave = cubit.addDriverAdvance(
          amount: '200.00',
          movementDate: BusinessDate(year: 2026, month: 9, day: 19),
        );
        driversRepository.drivers.clear();
        await cubit.refreshDriverReferencesFromRealtime();

        final saving = cubit.state as DriverFinanceLoaded;
        expect(saving.isSaving, isTrue);
        expect(saving.selectedDriverId, _driverId);

        mutationBarrier.complete();
        await pendingSave;
        await Future<void>.delayed(Duration.zero);

        final latest = cubit.state as DriverFinanceLoaded;
        expect(latest.isSaving, isFalse);
        expect(latest.drivers, isEmpty);
        expect(latest.selectedDriverId, isNull);
        expect(latest.activity, isNull);

        expect(financeRepository.addMovementCalls, 1);
      },
    );

    test(
      'returns the trusted company Business Date for movement forms',
      () async {
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
      },
    );
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
  _FakeDriversRepository? driversRepository,
}) {
  final provider =
      businessDateProvider ??
      _FakeCompanyBusinessDateProvider(
        BusinessDate(year: 2026, month: 9, day: 19),
      );
  final businessDateUseCase = GetCompanyBusinessDateUseCase(provider);

  balanceRepository.financeRepository = financeRepository;
  return DriverFinanceCubit(
    getDriversUseCase: GetDriversUseCase(
      driversRepository ?? _FakeDriversRepository(),
    ),
    canManageDriverFinanceUseCase: const CanManageDriverFinanceUseCase(),
    getCompanyBusinessDateUseCase: businessDateUseCase,
    getDriverTripOptionsUseCase: GetDriverTripOptionsUseCase(financeRepository),
    addDriverAdvanceUseCase: AddDriverAdvanceUseCase(financeRepository),
    addDriverChargeUseCase: AddDriverChargeUseCase(financeRepository),
    addDriverCashReturnUseCase: AddDriverCashReturnUseCase(financeRepository),
    getCurrentDriverBalanceActivityUseCase:
        GetCurrentDriverBalanceActivityUseCase(
          getCompanyBusinessDateUseCase: businessDateUseCase,
          getDriverBalanceActivityUseCase: GetDriverBalanceActivityUseCase(
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

DriverFinancialMovement _advance({required String id, required double amount}) {
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
  final List<Driver> drivers = [_driver];

  @override
  Future<Result<List<Driver>>> getDrivers({required String companyId}) async {
    return Success<List<Driver>>(List.unmodifiable(drivers));
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
  final List<DriverBalanceActivityEntry> expenseEntries = [];
  final Completer<void>? mutationBarrier;
  Completer<void>? movementsBarrier;
  UnexpectedFailure? movementsFailure;
  int addMovementCalls = 0;
  String? lastTripOptionsTimeZoneId;
  DriverFinancialMovementWriteData? lastWriteData;

  _FakeDriverFinanceRepository({
    List<DriverFinancialMovement>? movements,
    this.addedMovement,
    this.mutationBarrier,
  }) : movements = [...?movements];

  @override
  Future<Result<List<DriverFinancialMovement>>> getDriverMovements({
    required String companyId,
    required String driverId,
  }) async {
    final barrier = movementsBarrier;
    if (barrier != null) await barrier.future;
    final failure = movementsFailure;
    if (failure != null) {
      return FailureResult<List<DriverFinancialMovement>>(failure);
    }
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
    final barrier = mutationBarrier;
    if (barrier != null) await barrier.future;
    final movement = addedMovement;
    if (movement == null) throw StateError('No test movement configured.');
    movements.insert(0, movement);
    return Success(movement);
  }
}

final class _FakeDriverBalanceRepository
    implements DriverBalanceActivityRepository {
  final List<DriverBalance> balances;
  final List<BusinessDate> beforeExclusiveBoundaries = [];
  late _FakeDriverFinanceRepository financeRepository;
  int calls = 0;

  _FakeDriverBalanceRepository(this.balances);

  @override
  Future<Result<DriverBalanceActivity>> getDriverBalanceActivity({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    final barrier = financeRepository.movementsBarrier;
    if (barrier != null) await barrier.future;
    final failure = financeRepository.movementsFailure;
    if (failure != null) return FailureResult(failure);

    beforeExclusiveBoundaries.add(beforeExclusive);
    final old = balances[calls++];
    final checkpoint = old.checkpoint;
    final zero = Money(minorUnits: 0, currency: currency);
    final moneyBalance = DriverMoneyBalance(
      companyId: companyId,
      driverId: driverId,
      currency: currency,
      currencyFractionDigits: currencyFractionDigits,
      checkpoint: checkpoint == null
          ? null
          : DriverMoneyBalanceCheckpoint(
              settlementId: checkpoint.settlementId,
              periodEnd: checkpoint.periodEnd,
              snapshotCreatedAt: checkpoint.snapshotCreatedAt,
              closingBalance: Money(
                minorUnits: (checkpoint.closingBalance * 100).round(),
                currency: currency,
              ),
              currencyFractionDigits: currencyFractionDigits,
            ),
      totalAdvances: zero,
      totalDriverCharges: zero,
      totalTripExpenseCredits: zero,
      totalCashReturns: zero,
    );
    return Success(
      DriverBalanceActivity(
        canonicalBalance: moneyBalance,
        entries: [
          for (final movement in financeRepository.movements)
            DriverBalanceActivityEntry(
              source: DriverBalanceActivitySource.financialMovement,
              sourceId: movement.id,
              kind: switch (movement.type) {
                DriverFinancialMovementType.advance =>
                  DriverBalanceActivityKind.advance,
                DriverFinancialMovementType.driverCharge =>
                  DriverBalanceActivityKind.driverCharge,
                DriverFinancialMovementType.cashReturn =>
                  DriverBalanceActivityKind.cashReturn,
              },
              companyId: companyId,
              driverId: driverId,
              businessDate: movement.movementDate,
              createdAt: movement.createdAt ?? DateTime.utc(2026, 9, 19),
              amount: Money(
                minorUnits: (movement.amount * 100).round(),
                currency: currency,
              ),
            ),
          ...financeRepository.expenseEntries,
        ],
      ),
    );
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
