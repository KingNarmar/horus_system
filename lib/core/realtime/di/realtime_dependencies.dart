import '../../data/supabase/supabase_client_provider.dart';
import '../data/datasources/company_data_changes_remote_data_source.dart';
import '../data/repositories/company_data_changes_repository_impl.dart';
import '../domain/usecases/watch_company_data_changes_usecase.dart';
import '../presentation/cubit/company_realtime_cubit.dart';

abstract final class RealtimeDependencies {
  static CompanyRealtimeCubit createCubit() {
    final source = SupabaseCompanyDataChangesRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final repository = CompanyDataChangesRepositoryImpl(source);
    return CompanyRealtimeCubit(
      watchChanges: WatchCompanyDataChangesUseCase(repository),
    );
  }
}
