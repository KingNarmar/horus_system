import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/dashboard_remote_data_source.dart';
import '../data/repositories/dashboard_repository_impl.dart';
import '../domain/repositories/dashboard_repository.dart';
import '../domain/usecases/get_dashboard_summary_usecase.dart';
import '../presentation/cubit/dashboard_cubit.dart';

abstract final class DashboardDependencies {
  static DashboardRepository createRepository() {
    return DashboardRepositoryImpl(
      SupabaseDashboardRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static DashboardCubit createCubit() {
    return DashboardCubit(GetDashboardSummaryUseCase(createRepository()));
  }
}
