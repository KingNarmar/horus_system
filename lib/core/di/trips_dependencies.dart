import '../../features/audit/di/audit_dependencies.dart';
import '../../features/expense_types/di/expense_types_dependencies.dart';
import '../../features/expenses/di/expenses_dependencies.dart';
import '../../features/trips/data/datasources/trips_remote_data_source.dart';
import '../../features/trips/data/repositories/trips_repository_impl.dart';
import '../../features/trips/domain/usecases/trips_usecases.dart';
import '../../features/trips/presentation/cubit/trips_cubit.dart';
import '../data/services/timezone_business_time_zone_converter.dart';
import '../data/supabase/supabase_client_provider.dart';
import '../usecases/convert_instants_to_business_local_date_times_usecase.dart';

abstract final class TripsDependencies {
  static TripsCubit createTripsCubit() {
    final client = SupabaseClientProvider.client;
    const businessTimeZoneConverter = TimezoneBusinessTimeZoneConverter();

    final tripsRemoteDataSource = SupabaseTripsRemoteDataSource(client);
    final tripsRepository = TripsRepositoryImpl(
      remoteDataSource: tripsRemoteDataSource,
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
      getTripBusinessLocalTimestampsUseCase:
          const GetTripBusinessLocalTimestampsUseCase(
            businessTimeZoneConverter,
          ),
      resolveTripBusinessLocalTimestampsUseCase:
          const ResolveTripBusinessLocalTimestampsUseCase(
            businessTimeZoneConverter,
          ),
      convertInstantsToBusinessLocalDateTimesUseCase:
          const ConvertInstantsToBusinessLocalDateTimesUseCase(
            businessTimeZoneConverter,
          ),
      getTripAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
      getTripExpenseLedgerEntriesUseCase:
          ExpensesDependencies.createGetTripExpenseLedgerEntriesUseCase(),
      getExpenseTypeCatalogUseCase:
          ExpenseTypesDependencies.createGetExpenseTypeCatalogUseCase(),
      getLedgerEligibleExpenseTypesUseCase:
          ExpenseTypesDependencies.createGetLedgerEligibleExpenseTypesUseCase(),
      createTripExpenseUseCase:
          ExpensesDependencies.createCreateTripExpenseUseCase(),
      voidExpenseLedgerEntryUseCase:
          ExpensesDependencies.createVoidExpenseLedgerEntryUseCase(),
    );
  }
}
