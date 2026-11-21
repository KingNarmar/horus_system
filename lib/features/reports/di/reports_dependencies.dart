import '../../../core/config/app_config.dart';
import '../../../core/config/app_environment.dart';
import '../../../core/data/services/timezone_business_time_zone_converter.dart';
import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../company/di/company_dependencies.dart';
import '../data/datasources/report_export_snapshot_remote_data_source.dart';
import '../data/repositories/paged_reports_repository_impl.dart';
import '../data/repositories/report_pdf_delivery_repository_impl.dart';
import '../data/services/report_pdf_business_timestamp_formatter.dart';
import '../data/services/report_pdf_renderer_impl.dart';
import '../domain/repositories/report_export_sources_factory.dart';
import '../domain/usecases/prepare_report_export_usecase.dart';
import '../domain/usecases/reauthorize_report_pdf_print_usecase.dart';
import '../domain/usecases/generate_report_pdf_usecase.dart';
import '../domain/usecases/report_pdf_delivery_usecases.dart';
import '../presentation/cubit/report_export_cubit.dart';
import '../data/datasources/reports_remote_data_source.dart';
import '../data/repositories/reports_repository_impl.dart';
import '../domain/repositories/reports_repository.dart';
import '../domain/usecases/get_open_invoices_report_usecase.dart';
import '../domain/usecases/get_operational_report_usecase.dart';
import '../domain/usecases/get_trip_expenses_report_usecase.dart';
import '../domain/usecases/get_trip_net_profit_report_usecase.dart';
import '../presentation/cubit/reports_cubit.dart';

abstract final class ReportsDependencies {
  static ReportExportCubit createExportCubit() {
    final repository = createRepository();
    final prepare = PrepareReportExportUseCase(
      operational: GetOperationalReportUseCase(repository: repository),
      expenses: GetTripExpensesReportUseCase(repository),
      profit: GetTripNetProfitReportUseCase(repository: repository),
      invoices: GetOpenInvoicesReportUseCase(repository: repository),
      branding: CompanyDependencies.createBrandingRepository(),
      clock: DateTime.now,
      exportSourcesFactory: createSnapshotExportSourcesFactory(
        environment: AppConfig.fromCompileTimeEnvironment().environment,
        remote: SupabaseReportExportSnapshotRemoteDataSource(
          SupabaseClientProvider.client,
        ),
      ),
    );
    final delivery = ReportPdfDeliveryRepositoryImpl();
    return ReportExportCubit(
      generate: GenerateReportPdfUseCase(
        prepare: prepare,
        renderer: ReportPdfRendererImpl(
          timestampFormatter: const ReportPdfBusinessTimestampFormatter(
            TimezoneBusinessTimeZoneConverter(),
          ),
        ),
      ),
      reauthorizePrint: ReauthorizeReportPdfPrintUseCase(prepare),
      save: SaveReportPdfUseCase(delivery),
      print: PrintReportPdfUseCase(delivery),
      share: ShareReportPdfUseCase(delivery),
    );
  }

  /// Only the Development database has the versioned snapshot RPCs.
  /// Staging/Production retain the existing export source until their own
  /// rollout is approved. A failed paged export never falls back silently.
  static ReportExportSourcesFactory? createSnapshotExportSourcesFactory({
    required AppEnvironment environment,
    required ReportExportSnapshotRemoteDataSource remote,
  }) {
    if (environment != AppEnvironment.development) return null;

    return ({required cancellation, onProgress}) => PagedReportsRepositoryImpl(
      remote: remote,
      cancellation: cancellation,
      onProgress: onProgress,
    );
  }

  static ReportsRepository createRepository() {
    return ReportsRepositoryImpl(
      SupabaseReportsRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static ReportsCubit createCubit() {
    final repository = createRepository();
    return ReportsCubit(
      getOperationalReport: GetOperationalReportUseCase(repository: repository),
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
