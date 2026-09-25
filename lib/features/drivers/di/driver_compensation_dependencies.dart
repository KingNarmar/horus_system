import '../../../core/di/business_document_dependencies.dart';
import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../../core/usecases/get_company_business_date_usecase.dart';
import '../../company/di/company_dependencies.dart';
import '../data/datasources/driver_compensation_remote_data_source.dart';
import '../data/repositories/driver_compensation_repository_impl.dart';
import '../domain/repositories/driver_compensation_repository.dart';
import '../domain/usecases/attach_driver_compensation_contract_usecase.dart';
import '../domain/usecases/create_driver_compensation_revision_usecase.dart';
import '../domain/usecases/end_driver_compensation_revision_usecase.dart';
import '../domain/usecases/get_driver_compensation_contract_access_usecase.dart';
import '../domain/usecases/get_driver_compensation_history_usecase.dart';
import '../domain/usecases/resolve_driver_compensation_for_date_usecase.dart';
import '../domain/usecases/resolve_driver_compensation_for_period_usecase.dart';
import '../presentation/cubit/driver_compensation_cubit.dart';

abstract final class DriverCompensationDependencies {
  static DriverCompensationRepository createRepository() {
    return DriverCompensationRepositoryImpl(
      remoteDataSource: SupabaseDriverCompensationRemoteDataSource(
        SupabaseClientProvider.client,
      ),
      businessDocumentRepository:
          BusinessDocumentDependencies.createRepository(),
    );
  }

  static ResolveDriverCompensationForPeriodUseCase
  createResolveForPeriodUseCase() {
    return ResolveDriverCompensationForPeriodUseCase(createRepository());
  }

  static DriverCompensationCubit createCubit() {
    final repository = createRepository();
    final businessDateUseCase = GetCompanyBusinessDateUseCase(
      CompanyDependencies.createBusinessDateProvider(),
    );

    return DriverCompensationCubit(
      getCompanyBusinessDateUseCase: businessDateUseCase,
      getHistoryUseCase: GetDriverCompensationHistoryUseCase(repository),
      resolveForDateUseCase: ResolveDriverCompensationForDateUseCase(
        repository,
      ),
      createRevisionUseCase: CreateDriverCompensationRevisionUseCase(
        repository,
      ),
      endRevisionUseCase: EndDriverCompensationRevisionUseCase(repository),
      attachContractUseCase: AttachDriverCompensationContractUseCase(
        repository,
      ),
      contractAccessUseCase: GetDriverCompensationContractAccessUseCase(
        repository,
      ),
    );
  }
}
