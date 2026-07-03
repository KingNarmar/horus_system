import '../../features/audit/di/audit_dependencies.dart';
import '../../features/fleet/data/datasources/fleet_remote_data_source.dart';
import '../../features/fleet/data/repositories/fleet_repo_impl.dart';
import '../../features/fleet/domain/usecases/fleet_usecases.dart';
import '../../features/fleet/presentation/cubit/fleet_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class FleetDependencies {
  static FleetCubit createFleetCubit() {
    final client = SupabaseClientProvider.client;
    final remoteDataSource = SupabaseFleetRemoteDataSource(client);
    final repository = FleetRepositoryImpl(
      remoteDataSource: remoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
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
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
    );
  }
}
