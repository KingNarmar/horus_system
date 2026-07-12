import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../data/datasources/driver_settlements_remote_data_source.dart';
import '../data/repositories/driver_settlements_repository_impl.dart';
import '../domain/repositories/driver_settlements_repository.dart';
import '../domain/usecases/driver_settlement_usecases.dart';
import '../presentation/cubit/driver_settlements_cubit.dart';

abstract final class DriverSettlementsDependencies {
  static DriverSettlementsRepository createRepository() {
    final remoteDataSource = SupabaseDriverSettlementsRemoteDataSource(
      SupabaseClientProvider.client,
    );
    return DriverSettlementsRepositoryImpl(
      remoteDataSource: remoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static DriverSettlementsCubit createCubit() {
    final repository = createRepository();
    return DriverSettlementsCubit(
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
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
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
