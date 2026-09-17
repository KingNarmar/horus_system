import '../../../core/data/services/timezone_business_time_zone_converter.dart';
import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../audit/di/audit_dependencies.dart';
import '../../company/di/company_dependencies.dart';
import '../../driver_finance/di/driver_finance_dependencies.dart';
import '../../drivers/di/driver_compensation_dependencies.dart';
import '../data/datasources/driver_settlements_remote_data_source.dart';
import '../data/repositories/driver_settlements_repository_impl.dart';
import '../domain/repositories/driver_settlements_repository.dart';
import '../domain/usecases/driver_settlement_usecases.dart';
import '../presentation/cubit/driver_settlements_cubit.dart';

abstract final class DriverSettlementsDependencies {
  static DriverSettlementsRepositoryImpl _createRepositoryImpl() {
    final remoteDataSource = SupabaseDriverSettlementsRemoteDataSource(
      SupabaseClientProvider.client,
    );
    return DriverSettlementsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      moneyRemoteDataSource: remoteDataSource,
      driverBalanceRepository:
          DriverFinanceDependencies.createBalanceRepository(),
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static DriverSettlementsRepository createRepository() {
    return _createRepositoryImpl();
  }

  static ResolveDriverSettlementCalculationUseCase _createResolveCalculation(
    DriverSettlementsRepositoryImpl repository,
  ) {
    return ResolveDriverSettlementCalculationUseCase(
      repository: repository,
      moneyRepository: repository,
      resolveCompensation:
          DriverCompensationDependencies.createResolveForPeriodUseCase(),
      getCanonicalMoneyBalance:
          DriverFinanceDependencies.createGetCanonicalDriverMoneyBalanceUseCase(),
    );
  }

  static DriverSettlementsCubit createCubit() {
    final repository = _createRepositoryImpl();
    final resolveCalculation = _createResolveCalculation(repository);
    const businessTimeZoneConverter = TimezoneBusinessTimeZoneConverter();
    return DriverSettlementsCubit(
      getDriverSettlementsUseCase: GetDriverSettlementsUseCase(repository),
      getDriverOptionsUseCase: GetDriverSettlementDriverOptionsUseCase(
        repository,
      ),
      getBusinessDateUseCase: GetDriverSettlementBusinessDateUseCase(
        CompanyDependencies.createBusinessDateProvider(),
      ),
      getDriverSettlementDetailsUseCase: GetDriverSettlementDetailsUseCase(
        repository,
      ),
      calculatePreviewUseCase: CalculateDriverSettlementPreviewUseCase(
        resolveCalculation,
      ),
      createDraftUseCase: CreateDriverSettlementDraftUseCase(
        moneyRepository: repository,
        resolveCalculation: resolveCalculation,
      ),
      finalizeSettlementUseCase: FinalizeDriverSettlementUseCase(repository),
      voidSettlementUseCase: VoidDriverSettlementUseCase(repository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
      convertInstantsToBusinessLocalDateTimesUseCase:
          const ConvertInstantsToBusinessLocalDateTimesUseCase(
            businessTimeZoneConverter,
          ),
    );
  }

  static GetDriverSettlementsUseCase createGetDriverSettlementsUseCase() {
    return GetDriverSettlementsUseCase(createRepository());
  }

  static GetDriverSettlementDriverOptionsUseCase
  createGetDriverSettlementDriverOptionsUseCase() {
    return GetDriverSettlementDriverOptionsUseCase(createRepository());
  }

  static GetDriverSettlementDetailsUseCase
  createGetDriverSettlementDetailsUseCase() {
    return GetDriverSettlementDetailsUseCase(createRepository());
  }

  static CalculateDriverSettlementPreviewUseCase
  createCalculateDriverSettlementPreviewUseCase() {
    final repository = _createRepositoryImpl();
    return CalculateDriverSettlementPreviewUseCase(
      _createResolveCalculation(repository),
    );
  }

  static CreateDriverSettlementDraftUseCase
  createCreateDriverSettlementDraftUseCase() {
    final repository = _createRepositoryImpl();
    return CreateDriverSettlementDraftUseCase(
      moneyRepository: repository,
      resolveCalculation: _createResolveCalculation(repository),
    );
  }

  static FinalizeDriverSettlementUseCase
  createFinalizeDriverSettlementUseCase() {
    return FinalizeDriverSettlementUseCase(createRepository());
  }

  static VoidDriverSettlementUseCase createVoidDriverSettlementUseCase() {
    return VoidDriverSettlementUseCase(createRepository());
  }
}
