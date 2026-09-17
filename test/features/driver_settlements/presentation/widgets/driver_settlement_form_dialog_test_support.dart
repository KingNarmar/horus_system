import 'package:flutter/widgets.dart';
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
import 'package:horus_system/features/driver_settlements/presentation/cubit/driver_settlements_cubit.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_revision.dart';
import 'package:horus_system/features/drivers/domain/entities/driver_compensation_write_data.dart';
import 'package:horus_system/features/drivers/domain/repositories/driver_compensation_repository.dart';
import 'package:horus_system/features/drivers/domain/usecases/resolve_driver_compensation_for_period_usecase.dart';

import '../../../../helpers/fake_business_time_zone_converter.dart';

const formTestCompanyContext = CurrentCompanyContext(
  company: Company(
    id: 'company-1',
    name: 'Test Company',
    baseCurrencyCode: 'AED',
    baseCurrencyFractionDigits: 2,
  ),
  role: CompanyRole.accountant,
);

const formTestActiveDriver = DriverSettlementDriverOption(
  id: 'driver-1',
  displayName: 'Driver One',
  isActive: true,
);

BusinessDate formTestDate(int year, int month, int day) {
  return BusinessDate(year: year, month: month, day: day);
}

final class SettlementFormTestHarness {
  final FormTestSettlementMoneyRepository moneyRepository;
  final DriverSettlementsCubit cubit;

  SettlementFormTestHarness._({
    required this.moneyRepository,
    required this.cubit,
  });

  factory SettlementFormTestHarness.create() {
    final repository = FormTestDriverSettlementsRepository();
    final moneyRepository = FormTestSettlementMoneyRepository();
    final resolver = ResolveDriverSettlementCalculationUseCase(
      repository: repository,
      moneyRepository: moneyRepository,
      resolveCompensation: ResolveDriverCompensationForPeriodUseCase(
        FormTestCompensationRepository(),
      ),
      getCanonicalMoneyBalance: GetCanonicalDriverMoneyBalanceUseCase(
        FormTestMoneyBalanceRepository(),
      ),
    );

    return SettlementFormTestHarness._(
      moneyRepository: moneyRepository,
      cubit: DriverSettlementsCubit(
        getDriverSettlementsUseCase: GetDriverSettlementsUseCase(repository),
        getDriverOptionsUseCase: GetDriverSettlementDriverOptionsUseCase(
          repository,
        ),
        getBusinessDateUseCase: GetDriverSettlementBusinessDateUseCase(
          FormTestBusinessDateProvider(formTestDate(2026, 7, 31)),
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
          FormTestAuditLogRepository(),
        ),
        convertInstantsToBusinessLocalDateTimesUseCase:
            const ConvertInstantsToBusinessLocalDateTimesUseCase(
              FakeBusinessTimeZoneConverter(),
            ),
      ),
    );
  }
}

Future<void> setFormTestSurfaceSize(WidgetTester tester, Size size) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(() {
    tester.view.resetDevicePixelRatio();
    tester.view.resetPhysicalSize();
  });
}

final class FormTestBusinessDateProvider implements CompanyBusinessDateProvider {
  final BusinessDate date;

  const FormTestBusinessDateProvider(this.date);

  @override
  Future<Result<BusinessDate>> getBusinessDate({
    required String companyId,
  }) async {
    return Success(date);
  }
}

final class FormTestDriverSettlementsRepository
    implements DriverSettlementsRepository {
  @override
  Future<Result<List<DriverSettlement>>> getDriverSettlements({
    required String companyId,
    String? driverId,
    bool includeVoided = false,
  }) async {
    return const Success([]);
  }

  @override
  Future<Result<List<DriverSettlementDriverOption>>> getDriverOptions({
    required String companyId,
  }) async {
    return const Success([formTestActiveDriver]);
  }

  @override
  Future<Result<DriverSettlementDriverOption?>> getDriverOptionById({
    required String companyId,
    required String driverId,
  }) async {
    return Success(driverId == formTestActiveDriver.id ? formTestActiveDriver : null);
  }

  @override
  Future<Result<DriverSettlement>> getDriverSettlementById({
    required String companyId,
    required String settlementId,
  }) async {
    return Success(_historicalSettlement());
  }

  @override
  Future<Result<DriverSettlementSourceSnapshot>> getSettlementSourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
  }) {
    throw UnsupportedError('Legacy source path is not used by PC-09 form tests.');
  }

  @override
  Future<Result<DriverSettlement>> createDraft({
    required DriverSettlementDraftWriteData data,
    required String actorRole,
  }) {
    throw UnsupportedError('Legacy draft path is not used by PC-09 form tests.');
  }

  @override
  Future<Result<DriverSettlement>> finalizeSettlement({
    required DriverSettlementFinalizeData data,
    required String actorRole,
  }) async {
    return Success(_historicalSettlement());
  }

  @override
  Future<Result<DriverSettlement>> voidSettlement({
    required DriverSettlementVoidData data,
    required String actorRole,
  }) async {
    return Success(_historicalSettlement());
  }
}

final class FormTestSettlementMoneyRepository
    implements DriverSettlementMoneyRepository {
  int snapshotCalls = 0;

  @override
  Future<Result<DriverSettlementMoneySourceSnapshot>>
  getSettlementMoneySourceSnapshot({
    required String companyId,
    required String driverId,
    required DriverSettlementPeriod period,
    required CurrencyConfiguration currencyConfiguration,
  }) async {
    snapshotCalls++;
    final zero = Money(minorUnits: 0, currency: currencyConfiguration.currency);
    return Success(
      DriverSettlementMoneySourceSnapshot(
        openingDriverBalance: zero,
        advancesTotal: zero,
        driverPaidTripExpensesTotal: zero,
        returnedCashTotal: zero,
        deductionsTotal: zero,
      ),
    );
  }

  @override
  Future<Result<DriverSettlement>> createMoneyDraft({
    required DriverSettlementMoneyDraftWriteData data,
    required String actorRole,
  }) async {
    return Success(_historicalSettlement());
  }
}

final class FormTestCompensationRepository
    implements DriverCompensationRepository {
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
        effectiveFrom: formTestDate(2026, 1, 1),
      ),
    ]);
  }

  @override
  Future<Result<DriverCompensationRevision>> createRevision({
    required DriverCompensationWriteData data,
    required String actorRole,
    BusinessDocumentFile? contractDocument,
  }) => throw UnsupportedError('Not used by form tests.');

  @override
  Future<Result<DriverCompensationRevision>> endRevision({
    required String companyId,
    required String revisionId,
    required String driverId,
    required String actorRole,
    required BusinessDate effectiveTo,
  }) => throw UnsupportedError('Not used by form tests.');

  @override
  Future<Result<DriverCompensationRevision>> attachContractDocument({
    required DriverCompensationRevision revision,
    required String actorRole,
    required BusinessDocumentFile document,
  }) => throw UnsupportedError('Not used by form tests.');

  @override
  Future<Result<BusinessDocumentAccess>> createContractDocumentAccess({
    required String companyId,
    required DriverCompensationRevision revision,
  }) => throw UnsupportedError('Not used by form tests.');
}

final class FormTestMoneyBalanceRepository
    implements DriverMoneyBalanceRepository {
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

final class FormTestAuditLogRepository implements AuditLogRepository {
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

DriverSettlement _historicalSettlement() {
  return DriverSettlement(
    id: 'settlement-1',
    companyId: formTestCompanyContext.companyId,
    driverId: formTestActiveDriver.id,
    period: DriverSettlementPeriod(
      start: formTestDate(2026, 7, 1),
      end: formTestDate(2026, 7, 31),
    ),
    calculation: const DriverSettlementCalculationResult(
      openingDriverBalance: 0,
      advancesTotal: 0,
      driverPaidTripExpensesTotal: 0,
      returnedCashTotal: 0,
      deductionsTotal: 0,
      settlementDeductionsTotal: 0,
      grossSalary: 1000,
      salaryDeductionsTotal: 0,
      balanceDeductionApplied: 0,
      netSalaryPayable: 1000,
      closingDriverBalance: 0,
    ),
    status: DriverSettlementStatus.draft,
  );
}
