import '../../features/audit/di/audit_dependencies.dart';
import '../../features/routes/data/datasources/routes_remote_data_source.dart';
import '../../features/routes/data/repositories/routes_repository_impl.dart';
import '../../features/routes/domain/usecases/routes_usecases.dart';
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class RoutesDependencies {
  static RoutesCubit createRoutesCubit() {
    final client = SupabaseClientProvider.client;

    final routesRemoteDataSource = SupabaseRoutesRemoteDataSource(client);
    final routesRepository = RoutesRepositoryImpl(
      remoteDataSource: routesRemoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );

    return RoutesCubit(
      getRoutesUseCase: GetRoutesUseCase(routesRepository),
      saveRouteUseCase: SaveRouteUseCase(routesRepository),
      deactivateRouteUseCase: DeactivateRouteUseCase(routesRepository),
      reactivateRouteUseCase: ReactivateRouteUseCase(routesRepository),
      getRouteAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
    );
  }
}
