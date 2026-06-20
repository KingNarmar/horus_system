import '../../features/audit/data/datasources/audit_logs_remote_data_source.dart';
import '../../features/audit/data/repositories/audit_log_repository_impl.dart';
import '../../features/audit/domain/usecases/create_audit_log_usecase.dart';
import '../../features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../features/routes/data/datasources/routes_remote_data_source.dart';
import '../../features/routes/data/repositories/routes_repository_impl.dart';
import '../../features/routes/domain/usecases/routes_usecases.dart';
import '../../features/routes/presentation/cubit/routes_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class RoutesDependencies {
  static RoutesCubit createRoutesCubit() {
    final client = SupabaseClientProvider.client;

    final auditRemoteDataSource = SupabaseAuditLogsRemoteDataSource(client);
    final auditRepository = AuditLogRepositoryImpl(
      remoteDataSource: auditRemoteDataSource,
    );

    final routesRemoteDataSource = SupabaseRoutesRemoteDataSource(client);
    final routesRepository = RoutesRepositoryImpl(
      remoteDataSource: routesRemoteDataSource,
      createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
    );

    return RoutesCubit(
      getRoutesUseCase: GetRoutesUseCase(routesRepository),
      saveRouteUseCase: SaveRouteUseCase(routesRepository),
      deactivateRouteUseCase: DeactivateRouteUseCase(routesRepository),
      reactivateRouteUseCase: ReactivateRouteUseCase(routesRepository),
      getRouteAuditLogsUseCase: GetEntityAuditLogsUseCase(auditRepository),
    );
  }
}
