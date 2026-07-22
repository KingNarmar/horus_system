import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
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
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlements_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlement_form_input.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_cubit.dart';
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_state.dart';

void main() {
  late _FakeDriverSettlementsRepository repository;
  late DriverSettlementsCubit cubit;

  setUp(() {
    repository = _FakeDriverSettlementsRepository();
    cubit = DriverSettlementsCubit(
      getDriverSettlementsUseCase: GetDriverSettlementsUseCase(repository),
      getDriverOptionsUseCase: GetDriverSettlementDriverOptionsUseCase(
        repository,
      ),
      getDriverSettlementDetailsUseCase: GetDriverSettlementDetailsUseCase(
        repository,
      ),
      calculatePreviewUseCase: CalculateDriverSettlementPreviewUseCase(
        repository,
      ),
      createDraftUseCase: CreateDriverSettlementDraftUseCase(repository),
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
    expect(state.canManageDriverSettlements, isTrue);
  });

  test(
    'invalidating inputs prevents a stale preview from being emitted',
    () async {
      await cubit.loadDriverSettlements(_context);
      repository.snapshotCompleter = Completer();

      final previewFuture = cubit.calculatePreview(_formInput());
      cubit.invalidatePreview();
      repository.snapshotCompleter!.complete(
        const DriverSettlementSourceSnapshot(advancesTotal: 100),
      );
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
        _formInput(salaryDeductionsTotal: 50),
      );

      final state = cubit.state as DriverSettlementsLoaded;
      expect(created, isTrue);
      expect(state.allSettlements, hasLength(1));
      expect(state.feedback, DriverSettlementFeedback.draftCreated);
      expect(state.isCreatingDraft, isFalse);
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
  company: Company(id: 'company-1', name: 'Test Company'),
  role: CompanyRole.accountant,
);

DriverSettlementFormInput _formInput({double salaryDeductionsTotal = 0}) {
  return DriverSettlementFormInput(
    driverId: 'driver-active',
    periodStart: DateTime(2026, 7, 1),
    periodEnd: DateTime(2026, 7, 31),
    grossSalary: 1000,
    salaryDeductionsTotal: salaryDeductionsTotal,
    balanceDeductionApplied: 0,
    settlementDeductionsTotal: 0,
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
      start: DateTime(2026, 7, 1),
      end: DateTime(2026, 7, 31),
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

class _FakeDriverSettlementsRepository implements DriverSettlementsRepository {
  List<DriverSettlement> settlements = [];
  DriverSettlement? details;
  Completer<DriverSettlementSourceSnapshot>? snapshotCompleter;

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
  }) async {
    final completer = snapshotCompleter;
    if (completer != null) return Success(await completer.future);
    return const Success(DriverSettlementSourceSnapshot(advancesTotal: 100));
  }

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) async {
    final settlement = DriverSettlement(
      id: 'created-draft',
      companyId: data.companyId,
      driverId: data.driverId,
      period: data.period,
      calculation: data.calculation,
      status: DriverSettlementStatus.draft,
      notes: data.notes,
      items: data.items,
    );
    settlements = [settlement, ...settlements];
    details = settlement;
    return Success(settlement);
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
