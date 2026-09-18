import '../../features/audit/di/audit_dependencies.dart';
import '../../features/fleet/data/datasources/fleet_license_documents_remote_data_source.dart';
import '../../features/fleet/data/datasources/fleet_remote_data_source.dart';
import '../../features/fleet/data/repositories/fleet_license_documents_repository_impl.dart';
import '../../features/fleet/data/repositories/fleet_repo_impl.dart';
import '../../features/fleet/domain/usecases/fleet_license_document_usecases.dart';
import '../../features/fleet/domain/usecases/fleet_usecases.dart';
import '../../features/fleet/presentation/cubit/fleet_cubit.dart';
import '../../features/fleet/presentation/cubit/fleet_license_documents_cubit.dart';
import '../data/services/timezone_business_time_zone_converter.dart';
import '../data/supabase/supabase_client_provider.dart';
import '../usecases/convert_instants_to_business_local_date_times_usecase.dart';
import 'business_document_dependencies.dart';

abstract final class FleetDependencies {
  static FleetCubit createFleetCubit() {
    final client = SupabaseClientProvider.client;
    final remoteDataSource = SupabaseFleetRemoteDataSource(client);
    final repository = FleetRepositoryImpl(
      remoteDataSource: remoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
    const businessTimeZoneConverter = TimezoneBusinessTimeZoneConverter();
    return FleetCubit(
      getTractorHeadsUseCase: GetTractorHeadsUseCase(repository),
      getTrailersUseCase: GetTrailersUseCase(repository),
      canManageFleetUseCase: const CanManageFleetUseCase(),
      saveTractorHeadUseCase: SaveTractorHeadUseCase(repository),
      saveTrailerUseCase: SaveTrailerUseCase(repository),
      deactivateTractorHeadUseCase: DeactivateTractorHeadUseCase(repository),
      reactivateTractorHeadUseCase: ReactivateTractorHeadUseCase(repository),
      deactivateTrailerUseCase: DeactivateTrailerUseCase(repository),
      reactivateTrailerUseCase: ReactivateTrailerUseCase(repository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
      convertInstantsToBusinessLocalDateTimesUseCase:
          const ConvertInstantsToBusinessLocalDateTimesUseCase(
            businessTimeZoneConverter,
          ),
    );
  }

  static FleetLicenseDocumentsCubit createFleetLicenseDocumentsCubit() {
    final client = SupabaseClientProvider.client;
    final repository = FleetLicenseDocumentsRepositoryImpl(
      remoteDataSource: SupabaseFleetLicenseDocumentsRemoteDataSource(client),
      businessDocumentRepository:
          BusinessDocumentDependencies.createRepository(),
    );

    return FleetLicenseDocumentsCubit(
      getDocumentUseCase: GetFleetLicenseDocumentUseCase(repository),
      uploadDocumentUseCase: UploadFleetLicenseDocumentUseCase(repository),
      getDocumentAccessUseCase: GetFleetLicenseDocumentAccessUseCase(
        repository,
      ),
      downloadDocumentUseCase: DownloadFleetLicenseDocumentUseCase(repository),
      replaceDocumentUseCase: ReplaceFleetLicenseDocumentUseCase(repository),
      removeDocumentUseCase: RemoveFleetLicenseDocumentUseCase(repository),
      canManageFleetUseCase: const CanManageFleetUseCase(),
    );
  }
}
