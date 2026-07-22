import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../../driver_finance/di/driver_finance_dependencies.dart';
import '../data/datasources/driver_settlements_remote_data_source.dart';
import '../data/repositories/driver_settlements_repository_impl.dart';
import '../domain/repositories/driver_settlements_repository.dart';
import '../domain/usecases/driver_settlement_usecases.dart';

abstract final class DriverSettlementsDependencies {
  static DriverSettlementsRepository createRepository() {
    final remoteDataSource = SupabaseDriverSettlementsRemoteDataSource(
      SupabaseClientProvider.client,
    );
    return DriverSettlementsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      driverBalanceRepository:
          DriverFinanceDependencies.createBalanceRepository(),
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static GetDriverSettlementsUseCase createGetDriverSettlementsUseCase() {
    return GetDriverSettlementsUseCase(createRepository());
  }

  static GetDriverSettlementDetailsUseCase
  createGetDriverSettlementDetailsUseCase() {
    return GetDriverSettlementDetailsUseCase(createRepository());
  }

  static CalculateDriverSettlementPreviewUseCase
  createCalculateDriverSettlementPreviewUseCase() {
    return CalculateDriverSettlementPreviewUseCase(createRepository());
  }

  static CreateDriverSettlementDraftUseCase
  createCreateDriverSettlementDraftUseCase() {
    return CreateDriverSettlementDraftUseCase(createRepository());
  }

  static FinalizeDriverSettlementUseCase
  createFinalizeDriverSettlementUseCase() {
    return FinalizeDriverSettlementUseCase(createRepository());
  }

  static VoidDriverSettlementUseCase createVoidDriverSettlementUseCase() {
    return VoidDriverSettlementUseCase(createRepository());
  }
}
