import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_access.dart';
import 'package:horus_system/core/documents/domain/entities/business_document_file.dart';
import 'package:horus_system/core/domain/services/company_business_date_provider.dart';
import 'package:horus_system/core/domain/value_objects/business_date.dart';
import 'package:horus_system/core/domain/value_objects/currency_code.dart';
import 'package:horus_system/core/domain/value_objects/currency_configuration.dart';
import 'package:horus_system/core/domain/value_objects/money.dart';
import 'package:horus_system/core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/audit/domain/entities/audit_entity_type.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log.dart';
import 'package:horus_system/features/audit/domain/entities/audit_log_write_data.dart';
import 'package:horus_system/features/audit/domain/entities/audit_module.dart';
import 'package:horus_system/features/audit/domain/repositories/audit_log_repository.dart';
import 'package:horus_system/features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_finance/domain/entities/driver_money_balance.dart';
import 'package:horus_system/features/driver_finance/domain/repositories/driver_money_balance_repository.dart';
import 'package:horus_system/features/driver_finance/domain/usecases/get_canonical_driver_money_balance_usecase.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_money_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlement_money_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlements_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlement_form_input.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_cubit.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_state.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';

import '../../../../helpers/fake_business_time_zone_converter.dart';

void main() {
  late _FakeDriverSettlementsRepository repository;
  late _FakeSettlementMoneyRepository moneyRepository;
  late DriverSettlementsCubit cubit;

  setUp(() {
    repository = _FakeDriverSettlementsRepository();
    moneyRepository = _FakeSettlementMoneyRepository();
    final resolver = ResolveDriverSettlementCalculationUseCase(
      repository: repository,
      moneyRepository: moneyRepository,
      resolveCompensation: ResolveDriverCompensationForPeriodUseCase(
        _FakeCompensationRepository(),
      ),
      getCanonicalMoneyBalance: GetCanonicalDriverMoneyBalanceUseCase(
        _FakeMoneyBalanceRepository(),
      ),
    );
    cubit = DriverSettlementsCubit(
      convertInstantsToBusinessLocalDateTimesUseCase:
          const ConvertInstantsToBusinessLocalDateTimesUseCase(
            FakeBusinessTimeZoneConverter(),
          ),
      getDriverSettlementsUseCase: GetDriverSettlementsUseCase(repository),
      getDriverOptionsUseCase: GetDriverSettlementDriverOptionsUseCase(
        repository,
      ),
      getBusinessDateUseCase: GetDriverSettlementBusinessDateUseCase(
        _FixedBusinessDateProvider(_date(2026, 7, 31)),
      ),
      getDriverSettlementDetailsUseCase: GetDriverSettlementDetailsUseCase(
        repository,
      ),
      calculatePreviewUseCase: CalculateDriverSettlementPreviewUseCase(
        resolver,
      ),
      createDraftUseCase: CreateDriverSettlementDraftUseCase(
        moneyRepository: moneyRepository,
        resolveCalculation: resolver,
      ),
      finalizeSettlementUseCase: FinalizeDriverSettlementUseCase(repository),
      voidSettlementUseCase: VoidDriverSettlementUseCase(repository),
      getEntityAuditLogsUseCase: GetEntityAuditLogsUseCase(
        _FakeAuditLogRepository(),
      ),
    );
  });

  tearDown(() => cubit.close());

  test('loads settlements and driver options through use cases', () async {
    repository.settlements = [_settlement(id: 'draft-1')];

    await cubit.loadDriverSettlements(_context);

    final state = cubit.state as DriverSettlementsLoaded;
    expect(state.allSettlements, hasLength(1));
    expect(state.driverOptions, hasLength(2));
    expect(state.businessDate, _date(2026, 7, 31));
    expect(state.canManageDriverSettlements, isTrue);
  });

  test(
    'invalidating inputs prevents a stale exact preview from being emitted',
    () async {
      await cubit.loadDriverSettlements(_context);
      moneyRepository.snapshotCompleter = Completer();

      final previewFuture = cubit.calculatePreview(_formInput());
      cubit.invalidatePreview();
      moneyRepository.snapshotCompleter!.complete(_exactSnapshot());
      await previewFuture;

      final state = cubit.state as DriverSettlementsLoaded;
      expect(state.preview, isNull);
      expect(state.isPreviewLoading, isFalse);
    },
  );

  test(
    'creating a draft upserts the list and exposes scoped feedback',
    () async {
      await cubit.loadDriverSettlements(_context);

      final created = await cubit.createDraft(
        _formInput(salaryDeductionsTotal: '50.00'),
      );

      final state = cubit.state as DriverSettlementsLoaded;
      expect(created, isTrue);
      expect(state.allSettlements, hasLength(1));
      expect(state.feedback, DriverSettlementFeedback.draftCreated);
      expect(state.isCreatingDraft, isFalse);
      expect(moneyRepository.lastWriteData?.compensationRevisionId, 'revision-1');
    },
  );

  test(
    'finalizing updates the selected settlement without page loading',
    () async {
      final draft = _settlement(id: 'draft-1');
      repository.settlements = [draft];
      repository.details = draft;
      await cubit.loadDriverSettlements(_context);
      await cubit.loadSettlementDetails(draft);

      final finalized = await cubit.finalizeSettlement(draft);

      final state = cubit.state as DriverSettlementsLoaded;
      expect(finalized, isTrue);
      expect(
        state.selectedSettlement?.status,
        DriverSettlementStatus.finalized,
      );
      expect(state.pendingActionSettlementId, isNull);
      expect(state.feedback, DriverSettlementFeedback.finalized);
    },
  );
}

const _context = CurrentCompanyContext(
  company: Company(
    id: 'company-1',
    name: 'Test Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  role: CompanyRole.accountant,
);

BusinessDate _date(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

DriverSettlementFormInput _formInput({String salaryDeductionsTotal = ''}) {
  return DriverSettlementFormInput(
    driverId: 'driver-active',
    periodStart: _date(2026, 7, 1),
    periodEnd: _date(2026, 7, 31),
    salaryDeductionsTotal: salaryDeductionsTotal,
  );
}

DriverSettlementMoneySourceSnapshot _exactSnapshot() {
  final currency = CurrencyCode.tryParse('AED')!;
  final zero = Money(minorUnits: 0, currency: currency);
  return DriverSettlementMoneySourceSnapshot(
    openingDriverBalance: zero,
    advancesTotal: Money(minorUnits: 10000, currency: currency),
    driverPaidTripExpensesTotal: Money(minorUnits: 2000, currency: currency),
    returnedCashTotal: zero,
    deductionsTotal: zero,
  );
}

DriverSettlement _settlement({
  required String id,
  DriverSettlementStatus status = DriverSettlementStatus.draft,
}) {
  return DriverSettlement(
    id: id,
    companyId: 'company-1',
    driverId: 'driver-active',
    period: DriverSettlementPeriod(
      start: _date(2026, 7, 1),
      end: _date(2026, 7, 31),
    ),
    calculation: const DriverSettlementCalculationResult(
      openingDriverBalance: 0,
      advancesTotal: 100,
      driverPaidTripExpensesTotal: 20,
      returnedCashTotal: 0,
      deductionsTotal: 0,
      settlementDeductionsTotal: 0,
      grossSalary: 1000,
      salaryDeductionsTotal: 50,
      balanceDeductionApplied: 0,
      netSalaryPayable: 950,
      closingDriverBalance: -80,
    ),
    status: status,
  );
}

class _FixedBusinessDateProvider implements CompanyBusinessDateProvider {
  final BusinessDate date;

  _FixedBusinessDateProvider(this.date);

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    return Success(date);
  }
}

class _FakeDriverSettlementsRepository implements DriverSettlementsRepository {
  List<DriverSettlement> settlements = [];
  DriverSettlement? details;

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return Success(settlements);
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) async {
    return const Success([
      DriverSettlementDriverOption(
        id: 'driver-active',
        displayName: 'Active Driver',
        isActive: true,
      ),
      DriverSettlementDriverOption(
        id: 'driver-inactive',
        displayName: 'Old Driver',
        isActive: false,
      ),
    ]);
  }

  @override
  Future<Result<DriverSettlementDriverOption?>> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    return Success(
      driverId == 'driver-active'
          ? const DriverSettlementDriverOption(
              id: 'driver-active',
              displayName: 'Active Driver',
              isActive: true,
            )
          : null,
    );
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    return Success(
      details ?? settlements.firstWhere((item) => item.id == settlementId),
    );
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) {
    throw UnsupportedError('Legacy source path is not used by PC-09 cubit tests.');
  }

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) {
    throw UnsupportedError('Legacy draft path is not used by PC-09 cubit tests.');
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) async {
    final current =
        details ??
        settlements.firstWhere((item) => item.id == data.settlementId);
    final updated = DriverSettlement(
      id: current.id,
      companyId: current.companyId,
      driverId: current.driverId,
      period: current.period,
      calculation: current.calculation,
      status: DriverSettlementStatus.finalized,
      notes: current.notes,
      finalizedAt: DateTime(2026, 7, 12),
      items: current.items,
    );
    details = updated;
    settlements = settlements
        .map((item) => item.id == updated.id ? updated : item)
        .toList();
    return Success(updated);
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) async {
    final current =
        details ??
        settlements.firstWhere((item) => item.id == data.settlementId);
    final updated = DriverSettlement(
      id: current.id,
      companyId: current.companyId,
      driverId: current.driverId,
      period: current.period,
      calculation: current.calculation,
      status: DriverSettlementStatus.voided,
      notes: current.notes,
      voidedAt: DateTime(2026, 7, 12),
      voidReason: data.reason,
      items: current.items,
    );
    details = updated;
    return Success(updated);
  }
}

class _FakeSettlementMoneyRepository implements DriverSettlementMoneyRepository {
  Completer<DriverSettlementMoneySourceSnapshot>? snapshotCompleter;
  DriverSettlementMoneyDraftWriteData? lastWriteData;

  @override
  Future<Result<DriverSettlementMoneySourceSnapshot>>
  getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  }) async {
    final completer = snapshotCompleter;
    if (completer != null) return Success(await completer.future);
    return Success(_exactSnapshot());
  }

  @override
  Future<Result<DriverSettlement>> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
    required String actorRole,
  }) async {
    lastWriteData = data;
    return Success(_settlement(id: 'created-draft'));
  }
}

class _FakeCompensationRepository implements DriverCompensationRepository {
  @override
  Future<Result<List<DriverCompensationRevision>>> getHistory({
    required String companyId,
    required String driverId,
  }) async {
    final currency = CurrencyCode.tryParse('AED')!;
    return Success([
      DriverCompensationRevision(
        id: 'revision-1',
        companyId: companyId,
        driverId: driverId,
        amount: Money(minorUnits: 100000, currency: currency),
        currencyFractionDigits: 2,
        effectiveFrom: _date(2026, 1, 1),
      ),
    ]);
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) {
    throw UnsupportedError('Not used by cubit tests.');
  }

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  }) {
    throw UnsupportedError('Not used by cubit tests.');
  }

  @override
  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  }) {
    throw UnsupportedError('Not used by cubit tests.');
  }

  @override
  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  }) {
    throw UnsupportedError('Not used by cubit tests.');
  }
}

class _FakeMoneyBalanceRepository implements DriverMoneyBalanceRepository {
  @override
  Future<Result<DriverMoneyBalance>> getCanonicalDriverMoneyBalance({
    required String companyId,
    required String driverId,
    required CurrencyCode currency,
    required int currencyFractionDigits,
    required BusinessDate beforeExclusive,
    BusinessDate? checkpointBeforeExclusive,
  }) async {
    final zero = Money(minorUnits: 0, currency: currency);
    return Success(
      DriverMoneyBalance(
        companyId: companyId,
        driverId: driverId,
        currency: currency,
        currencyFractionDigits: currencyFractionDigits,
        totalAdvances: zero,
        totalDriverCharges: zero,
        totalTripExpenseCredits: zero,
        totalCashReturns: zero,
      ),
    );
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
    return const Success([]);
  }
}
