import '../../features/audit/data/datasources/audit_logs_remote_data_source.dart';
import '../../features/audit/data/repositories/audit_log_repository_impl.dart';
import '../../features/audit/domain/usecases/create_audit_log_usecase.dart';
import '../../features/audit/domain/usecases/get_entity_audit_logs_usecase.dart';
import '../../features/trips/data/datasources/trips_remote_data_source.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/usecases/trips_usecases.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class TripsDependencies {
  static TripsCubit createTripsCubit() {
    final client = SupabaseClientProvider.client;

    final auditRemoteDataSource = SupabaseAuditLogsRemoteDataSource(client);
    final auditRepository = AuditLogRepositoryImpl(
      remoteDataSource: auditRemoteDataSource,
    );

    final tripsRemoteDataSource = SupabaseTripsRemoteDataSource(client);
    final tripsRepository = TripsRepositoryImpl(
      remoteDataSource: tripsRemoteDataSource,
      createAuditLogUseCase: CreateAuditLogUseCase(auditRepository),
    );

    return TripsCubit(
      getTripsUseCase: GetTripsUseCase(tripsRepository),
      getTripDetailsUseCase: GetTripDetailsUseCase(tripsRepository),
      getTripFormLookupsUseCase: GetTripFormLookupsUseCase(tripsRepository),
      createTripUseCase: CreateTripUseCase(tripsRepository),
      saveTripUseCase: SaveTripUseCase(tripsRepository),
      updateTripStatusUseCase: UpdateTripStatusUseCase(tripsRepository),
      getTripStatusHistoryUseCase: GetTripStatusHistoryUseCase(tripsRepository),
      calculateTripNetProfitUseCase: const CalculateTripNetProfitUseCase(),
      getTripAuditLogsUseCase: GetEntityAuditLogsUseCase(auditRepository),
    );
  }
}
