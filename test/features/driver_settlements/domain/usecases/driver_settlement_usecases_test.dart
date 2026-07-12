import 'package:horus_system/core/errors/failure_codes.dart';
import 'package:horus_system/core/utils/result.dart';
import 'package:horus_system/features/company/domain/entities/company.dart';
import 'package:horus_system/features/company/domain/entities/company_role.dart';
import 'package:horus_system/features/company/domain/entities/current_company_context.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_calculation_result.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_driver_option.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_direction.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_item_source_type.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_period.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_source_snapshot.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_status.dart';
import 'package:horus_system/features/driver_settlements/domain/entities/driver_settlement_write_data.dart';
import 'package:horus_system/features/driver_settlements/domain/repositories/driver_settlements_repository.dart';
import 'package:horus_system/features/driver_settlements/domain/usecases/driver_settlement_usecases.dart';
import 'package:test/test.dart';

void main() {
  group('Driver settlement use cases', () {
    test('calculates preview from repository source snapshot', () async {
      final repository = _FakeDriverSettlementsRepository(
        snapshot: DriverSettlementSourceSnapshot(
          openingDriverBalance: 25,
          advancesTotal: 300,
          driverPaidTripExpensesTotal: 100,
          returnedCashTotal: 50,
          deductionsTotal: 25,
          sourceItems: [
            DriverSettlementItem(
              companyId: _companyId,
              sourceType:
                  DriverSettlementItemSourceType.driverFinancialMovement,
              sourceId: 'movement-1',
              direction: DriverSettlementItemDirection.driverToCompany,
              amount: 300,
              labelKey: 'driver_settlement_item_advance',
            ),
          ],
        ),
      );
      final useCase = CalculateDriverSettlementPreviewUseCase(repository);

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.owner),
          driverId: _driverId,
          periodStart: DateTime(2026, 7),
          periodEnd: DateTime(2026, 7, 31),
          grossSalary: 1000,
          salaryDeductionsTotal: 100,
          balanceDeductionApplied: 50,
        ),
      );

      expect(result, isA<Success>());
      final preview = result.dataOrNull!;
      expect(preview.calculation.closingDriverBalance, 150);
      expect(preview.calculation.netSalaryPayable, 850);
      expect(preview.items, hasLength(1));
      expect(repository.snapshotCalls, 1);
    });

    test('loads company-scoped driver options for finance roles', () async {
      final repository = _FakeDriverSettlementsRepository();
      final useCase = GetDriverSettlementDriverOptionsUseCase(repository);

      final result = await useCase(
        GetDriverSettlementDriverOptionsParams(
          currentCompanyContext: _context(CompanyRole.accountant),
        ),
      );

      expect(result, isA<Success>());
      expect(result.dataOrNull, hasLength(1));
      expect(repository.driverOptionsCalls, 1);
    });

    test(
      'blocks draft creation for non-finance roles before repository calls',
      () async {
        final repository = _FakeDriverSettlementsRepository();
        final useCase = CreateDriverSettlementDraftUseCase(repository);

        final result = await useCase(
          CreateDriverSettlementDraftParams(
            currentCompanyContext: _context(CompanyRole.viewer),
            driverId: _driverId,
            periodStart: DateTime(2026, 7),
            periodEnd: DateTime(2026, 7, 31),
          ),
        );

        expect(result, isA<FailureResult>());
        expect(
          result.failureOrNull?.code,
          FailureCodes.permissionDriverSettlementsManagement,
        );
        expect(repository.snapshotCalls, 0);
        expect(repository.createDraftCalls, 0);
      },
    );

    test('rejects invalid settlement periods', () async {
      final repository = _FakeDriverSettlementsRepository();
      final useCase = CalculateDriverSettlementPreviewUseCase(repository);

      final result = await useCase(
        DriverSettlementCalculationParams(
          currentCompanyContext: _context(CompanyRole.accountant),
          driverId: _driverId,
          periodStart: DateTime(2026, 8),
          periodEnd: DateTime(2026, 7),
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverSettlementPeriodInvalid,
      );
      expect(repository.snapshotCalls, 0);
    });

    test('requires a void reason', () async {
      final repository = _FakeDriverSettlementsRepository();
      final useCase = VoidDriverSettlementUseCase(repository);

      final result = await useCase(
        VoidDriverSettlementParams(
          currentCompanyContext: _context(CompanyRole.admin),
          settlementId: 'settlement-1',
          reason: '  ',
        ),
      );

      expect(result, isA<FailureResult>());
      expect(
        result.failureOrNull?.code,
        FailureCodes.validationDriverSettlementVoidReasonRequired,
      );
      expect(repository.voidCalls, 0);
    });
  });
}

const _companyId = 'company-1';
const _driverId = 'driver-1';

CurrentCompanyContext _context(CompanyRole role) {
  return CurrentCompanyContext(
    company: const Company(id: _companyId, name: 'Company'),
    role: role,
  );
}

class _FakeDriverSettlementsRepository implements DriverSettlementsRepository {
  final DriverSettlementSourceSnapshot snapshot;
  int snapshotCalls = 0;
  int createDraftCalls = 0;
  int voidCalls = 0;
  int driverOptionsCalls = 0;

  _FakeDriverSettlementsRepository({
    this.snapshot = const DriverSettlementSourceSnapshot(),
  });

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) async {
    createDraftCalls++;
    return Success(_settlement(data: data));
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) async {
    return Success(_settlement(status: DriverSettlementStatus.finalized));
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    return Success(_settlement());
  }

  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return Success([_settlement()]);
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) async {
    driverOptionsCalls++;
    return const Success([
      DriverSettlementDriverOption(
        id: _driverId,
        displayName: 'Driver',
        isActive: true,
      ),
    ]);
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) async {
    snapshotCalls++;
    return Success(snapshot);
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) async {
    voidCalls++;
    return Success(_settlement(status: DriverSettlementStatus.voided));
  }

  DriverSettlement _settlement({
    DriverSettlementDraftWriteData? data,
    DriverSettlementStatus status = DriverSettlementStatus.draft,
  }) {
    final calculation =
        data?.calculation ??
        const DriverSettlementCalculationResult(
          openingDriverBalance: 0,
          advancesTotal: 0,
          driverPaidTripExpensesTotal: 0,
          returnedCashTotal: 0,
          deductionsTotal: 0,
          settlementDeductionsTotal: 0,
          grossSalary: 0,
          salaryDeductionsTotal: 0,
          balanceDeductionApplied: 0,
          netSalaryPayable: 0,
          closingDriverBalance: 0,
        );

    return DriverSettlement(
      id: 'settlement-1',
      companyId: data?.companyId ?? _companyId,
      driverId: data?.driverId ?? _driverId,
      period:
          data?.period ??
          DriverSettlementPeriod(
            start: DateTime(2026, 7),
            end: DateTime(2026, 7, 31),
          ),
      calculation: calculation,
      status: status,
      items: data?.items ?? const [],
    );
  }
}
