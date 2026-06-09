import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/company/data/datasources/company_remote_data_source.dart';
import '../../features/company/data/repositories/company_repository_impl.dart';
import '../../features/company/domain/usecases/create_company_usecase.dart';
import '../../features/company/domain/usecases/get_my_companies_usecase.dart';
import '../../features/company/presentation/cubit/company_onboarding_cubit.dart';
import '../data/supabase/supabase_client_provider.dart';

abstract final class AppDependencies {
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
}
