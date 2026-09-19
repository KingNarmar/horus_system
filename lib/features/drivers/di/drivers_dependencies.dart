import '../../../core/data/services/timezone_business_time_zone_converter.dart';
import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../../core/usecases/convert_instants_to_business_local_date_times_usecase.dart';
import '../../../core/usecases/get_company_business_date_usecase.dart';
import '../../audit/di/audit_dependencies.dart';
import '../../company/di/company_dependencies.dart';
import '../data/datasources/driver_images_remote_data_source.dart';
import '../data/datasources/drivers_remote_data_source.dart';
import '../data/repositories/drivers_repository_impl.dart';
import '../domain/repositories/drivers_repository.dart';
import '../domain/usecases/add_driver_usecase.dart';
import '../domain/usecases/deactivate_driver_usecase.dart';
import '../domain/usecases/get_driver_image_urls_usecase.dart';
import '../domain/usecases/get_drivers_usecase.dart';
import '../domain/usecases/reactivate_driver_usecase.dart';
import '../domain/usecases/update_driver_usecase.dart';
import '../presentation/cubit/drivers_cubit.dart';

abstract final class DriversDependencies {
  static DriversRepository createRepository() {
    return DriversRepositoryImpl(
      remoteDataSource: SupabaseDriversRemoteDataSource(
        SupabaseClientProvider.client,
      ),
      imagesRemoteDataSource: SupabaseDriverImagesRemoteDataSource(
        SupabaseClientProvider.client,
      ),
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static GetDriversUseCase createGetDriversUseCase() {
    return GetDriversUseCase(createRepository());
  }

  static DriversCubit createCubit() {
    final repository = createRepository();
    const businessTimeZoneConverter = TimezoneBusinessTimeZoneConverter();

    return DriversCubit(
      getDriversUseCase: GetDriversUseCase(repository),
      getDriverImageUrlsUseCase: GetDriverImageUrlsUseCase(repository),
      addDriverUseCase: AddDriverUseCase(repository),
      updateDriverUseCase: UpdateDriverUseCase(repository),
      deactivateDriverUseCase: DeactivateDriverUseCase(repository),
      reactivateDriverUseCase: ReactivateDriverUseCase(repository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
      convertInstantsToBusinessLocalDateTimesUseCase:
          const ConvertInstantsToBusinessLocalDateTimesUseCase(
            businessTimeZoneConverter,
          ),
      getCompanyBusinessDateUseCase: GetCompanyBusinessDateUseCase(
        CompanyDependencies.createBusinessDateProvider(),
      ),
    );
  }
}
