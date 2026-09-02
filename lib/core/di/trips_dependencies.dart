import '../../features/audit/di/audit_dependencies.dart';
import '../../features/expense_types/di/expense_types_dependencies.dart';
import '../../features/expenses/data/datasources/trip_expenses_remote_data_source.dart';
import '../../features/expenses/data/repositories/trip_expense_repo_impl.dart';
import '../../features/expenses/domain/usecases/trip_expenses_usecases.dart';
import '../../features/trips/data/datasources/trips_remote_data_source.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/usecases/trips_usecases.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class TripsDependencies {
  static TripsCubit createTripsCubit() {
    final client = SupabaseClientProvider.client;
    final createAuditLogUseCase = AuditDependencies.createAuditLogUseCase;

    final tripsRemoteDataSource = SupabaseTripsRemoteDataSource(client);
    final tripsRepository = TripsRepositoryImpl(
      remoteDataSource: tripsRemoteDataSource,
      createAuditLogUseCase: createAuditLogUseCase,
    );

    final expensesRemoteDataSource = SupabaseTripExpensesRemoteDataSource(client);
    final expensesRepository = TripExpensesRepositoryImpl(
      remoteDataSource: expensesRemoteDataSource,
      createAuditLogUseCase: createAuditLogUseCase,
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
      getTripAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
      getTripExpensesUseCase: GetTripExpensesUseCase(expensesRepository),
      getActiveExpenseTypesUseCase:
          ExpenseTypesDependencies.createGetActiveExpenseTypesUseCase(),
      addTripExpenseUseCase: AddTripExpenseUseCase(expensesRepository),
      updateTripExpenseUseCase: UpdateTripExpenseUseCase(expensesRepository),
    );
  }
}
