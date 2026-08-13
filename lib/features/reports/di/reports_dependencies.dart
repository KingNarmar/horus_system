import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/reports_remote_data_source.dart';
import '../data/repositories/reports_repository_impl.dart';
import '../domain/repositories/reports_repository.dart';
import '../domain/usecases/get_open_invoices_report_usecase.dart';
import '../domain/usecases/get_operational_report_usecase.dart';
import '../domain/usecases/get_trip_expenses_report_usecase.dart';
import '../domain/usecases/get_trip_net_profit_report_usecase.dart';
import '../presentation/cubit/reports_cubit.dart';

abstract final class ReportsDependencies {
  static ReportsRepository createRepository() {
    return ReportsRepositoryImpl(
      SupabaseReportsRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static ReportsCubit createCubit() {
    final repository = createRepository();
    return ReportsCubit(
      getOperationalReport: GetOperationalReportUseCase(
        repository: repository,
      ),
      getTripExpensesReport: GetTripExpensesReportUseCase(repository),
      getTripNetProfitReport: GetTripNetProfitReportUseCase(
        repository: repository,
      ),
      getOpenInvoicesReport: GetOpenInvoicesReportUseCase(
        repository: repository,
      ),
    );
  }
}
