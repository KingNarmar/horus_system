import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/audit_logs_remote_data_source.dart';
import '../data/repositories/audit_log_repository_impl.dart';
import '../domain/repositories/audit_log_repository.dart';
import '../domain/usecases/create_audit_log_usecase.dart';
import '../domain/usecases/get_entity_audit_logs_usecase.dart';

abstract final class AuditDependencies {
  static AuditLogsRemoteDataSource? _remoteDataSourceInstance;
  static AuditLogsRemoteDataSource get remoteDataSource =>
      _remoteDataSourceInstance ??= SupabaseAuditLogsRemoteDataSource(
        SupabaseClientProvider.client,
      );

  static AuditLogRepository? _repositoryInstance;
  static AuditLogRepository get repository =>
      _repositoryInstance ??= AuditLogRepositoryImpl(
        remoteDataSource: remoteDataSource,
      );

  static CreateAuditLogUseCase? _createAuditLogUseCaseInstance;
  static CreateAuditLogUseCase get createAuditLogUseCase =>
      _createAuditLogUseCaseInstance ??= CreateAuditLogUseCase(repository);

  static GetEntityAuditLogsUseCase? _getEntityAuditLogsUseCaseInstance;
  static GetEntityAuditLogsUseCase get getEntityAuditLogsUseCase =>
      _getEntityAuditLogsUseCaseInstance ??= GetEntityAuditLogsUseCase(
        repository,
      );
}
