import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/company/data/datasources/company_context_remote_data_source.dart';
import '../../features/company/data/datasources/company_remote_data_source.dart';
import '../../features/company/data/datasources/company_users_remote_data_source.dart';
import '../../features/company/data/repositories/company_context_repository_impl.dart';
import '../../features/company/data/repositories/company_repository_impl.dart';
import '../../features/company/data/repositories/company_users_repository_impl.dart';
import '../../features/company/domain/usecases/clear_current_company_context_usecase.dart';
import '../../features/company/domain/usecases/create_company_usecase.dart';
import '../../features/company/domain/usecases/get_company_users_usecase.dart';
import '../../features/company/domain/usecases/get_my_companies_usecase.dart';
import '../../features/company/domain/usecases/load_current_company_context_usecase.dart';
import '../../features/company/domain/usecases/select_current_company_usecase.dart';
import '../../features/company/presentation/cubit/company_onboarding_cubit.dart';
import '../../features/company/presentation/cubit/company_users_cubit.dart';
import '../../features/company/presentation/cubit/current_company_cubit.dart';
import '../context/current_company_provider.dart';
import '../context/in_memory_current_company_provider.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class AppDependencies {
  static final CurrentCompanyProvider _currentCompanyProvider =
      InMemoryCurrentCompanyProvider();

  static CurrentCompanyProvider get currentCompanyProvider =>
      _currentCompanyProvider;

  static AuthCubit createAuthCubit() {
    final authRemoteDataSource = SupabaseAuthRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final authRepository = AuthRepositoryImpl(authRemoteDataSource);

    return AuthCubit(
      loginUseCase: LoginUseCase(authRepository),
      logoutUseCase: LogoutUseCase(authRepository),
      getCurrentUserUseCase: GetCurrentUserUseCase(authRepository),
    );
  }

  static CompanyOnboardingCubit createCompanyOnboardingCubit() {
    final companyRemoteDataSource = SupabaseCompanyRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final companyRepository = CompanyRepositoryImpl(companyRemoteDataSource);

    return CompanyOnboardingCubit(
      createCompanyUseCase: CreateCompanyUseCase(companyRepository),
      getMyCompaniesUseCase: GetMyCompaniesUseCase(companyRepository),
    );
  }

  static CurrentCompanyCubit createCurrentCompanyCubit() {
    final companyContextRemoteDataSource =
        SupabaseCompanyContextRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final companyContextRepository = CompanyContextRepositoryImpl(
      remoteDataSource: companyContextRemoteDataSource,
      currentCompanyProvider: _currentCompanyProvider,
    );

    return CurrentCompanyCubit(
      loadCurrentCompanyContextUseCase: LoadCurrentCompanyContextUseCase(
        companyContextRepository,
      ),
      selectCurrentCompanyUseCase: SelectCurrentCompanyUseCase(
        companyContextRepository,
      ),
      clearCurrentCompanyContextUseCase: ClearCurrentCompanyContextUseCase(
        companyContextRepository,
      ),
    );
  }

  static CompanyUsersCubit createCompanyUsersCubit() {
    final companyUsersRemoteDataSource = SupabaseCompanyUsersRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final companyUsersRepository = CompanyUsersRepositoryImpl(
      remoteDataSource: companyUsersRemoteDataSource,
      currentCompanyProvider: _currentCompanyProvider,
    );

    return CompanyUsersCubit(
      getCompanyUsersUseCase: GetCompanyUsersUseCase(companyUsersRepository),
    );
  }
}
