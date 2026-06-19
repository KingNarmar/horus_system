import '../../features/audit/data/datasources/audit_logs_remote_data_source.dart';
import '../../features/audit/data/repositories/audit_log_repository_impl.dart';
import '../../features/audit/domain/usecases/create_audit_log_usecase.dart';
import '../../features/fleet/data/datasources/fleet_remote_data_source.dart';
import '../../features/fleet/data/repositories/fleet_repo_impl.dart';
import '../../features/fleet/domain/usecases/fleet_usecases.dart';
import '../../features/fleet/presentation/cubit/fleet_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class FleetDependencies {
  static FleetCubit createFleetCubit() {
    final client = SupabaseClientProvider.client;
    final remoteDataSource = SupabaseFleetRemoteDataSource(client);
    final auditRemoteDataSource = SupabaseAuditLogsRemoteDataSource(client);
    final auditRepository = AuditLogRepositoryImpl(remoteDataSource: auditRemoteDataSource);
    final repository = FleetRepositoryImpl(
      remoteDataSource: remoteDataSource,
      createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
    );
    return FleetCubit(
      getTractorHeadsUseCase: GetTractorHeadsUseCase(repository),
      getTrailersUseCase: GetTrailersUseCase(repository),
      saveTractorHeadUseCase: SaveTractorHeadUseCase(repository),
      saveTrailerUseCase: SaveTrailerUseCase(repository),
      deactivateTractorHeadUseCase: DeactivateTractorHeadUseCase(repository),
      reactivateTractorHeadUseCase: ReactivateTractorHeadUseCase(repository),
      deactivateTrailerUseCase: DeactivateTrailerUseCase(repository),
      reactivateTrailerUseCase: ReactivateTrailerUseCase(repository),
    );
  }
}
