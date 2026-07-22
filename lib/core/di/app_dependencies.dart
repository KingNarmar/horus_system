import '../../features/audit/di/audit_dependencies.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
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
import '../../features/customers/data/datasources/customers_remote_data_source.dart';
import '../../features/customers/data/repositories/customers_repository_impl.dart';
import '../../features/customers/domain/usecases/add_customer_usecase.dart';
import '../../features/customers/domain/usecases/deactivate_customer_usecase.dart';
import '../../features/customers/domain/usecases/get_customers_usecase.dart';
import '../../features/customers/domain/usecases/reactivate_customer_usecase.dart';
import '../../features/customers/domain/usecases/update_customer_usecase.dart';
import '../../features/customers/presentation/cubit/customers_cubit.dart';
import '../../features/driver_finance/di/driver_finance_dependencies.dart';
import '../../features/driver_finance/domain/usecases/driver_finance_usecases.dart';
import '../../features/driver_finance/domain/usecases/get_canonical_driver_balance_usecase.dart';
import '../../features/drivers/data/datasources/drivers_remote_data_source.dart';
import '../../features/drivers/data/repositories/drivers_repository_impl.dart';
import '../../features/drivers/domain/usecases/add_driver_usecase.dart';
import '../../features/drivers/domain/usecases/deactivate_driver_usecase.dart';
import '../../features/drivers/domain/usecases/get_drivers_usecase.dart';
import '../../features/drivers/domain/usecases/reactivate_driver_usecase.dart';
import '../../features/drivers/domain/usecases/update_driver_usecase.dart';
import '../../features/drivers/presentation/cubit/drivers_cubit.dart';
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
      registerUseCase: RegisterUseCase(authRepository),
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
        SupabaseCompanyContextRemoteDataSource(SupabaseClientProvider.client);
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
    );
    return CompanyUsersCubit(
      getCompanyUsersUseCase: GetCompanyUsersUseCase(companyUsersRepository),
    );
  }

  static CustomersCubit createCustomersCubit() {
    final customersRemoteDataSource = SupabaseCustomersRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final customersRepository = CustomersRepositoryImpl(
      remoteDataSource: customersRemoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
    return CustomersCubit(
      getCustomersUseCase: GetCustomersUseCase(customersRepository),
      addCustomerUseCase: AddCustomerUseCase(customersRepository),
      updateCustomerUseCase: UpdateCustomerUseCase(customersRepository),
      deactivateCustomerUseCase: DeactivateCustomerUseCase(customersRepository),
      reactivateCustomerUseCase: ReactivateCustomerUseCase(customersRepository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
    );
  }

  static DriversCubit createDriversCubit() {
    final driversRemoteDataSource = SupabaseDriversRemoteDataSource(
      SupabaseClientProvider.client,
    );
    final driversRepository = DriversRepositoryImpl(
      remoteDataSource: driversRemoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
    final driverFinanceRepository =
        DriverFinanceDependencies.createRepository();
    final driverBalanceRepository =
        DriverFinanceDependencies.createBalanceRepository();

    return DriversCubit(
      getDriversUseCase: GetDriversUseCase(driversRepository),
      addDriverUseCase: AddDriverUseCase(driversRepository),
      updateDriverUseCase: UpdateDriverUseCase(driversRepository),
      deactivateDriverUseCase: DeactivateDriverUseCase(driversRepository),
      reactivateDriverUseCase: ReactivateDriverUseCase(driversRepository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
      getDriverMovementsUseCase: GetDriverMovementsUseCase(
        driverFinanceRepository,
      ),
      getDriverTripOptionsUseCase: GetDriverTripOptionsUseCase(
        driverFinanceRepository,
      ),
      addDriverAdvanceUseCase: AddDriverAdvanceUseCase(driverFinanceRepository),
      addDriverChargeUseCase: AddDriverChargeUseCase(driverFinanceRepository),
      addDriverCashReturnUseCase: AddDriverCashReturnUseCase(
        driverFinanceRepository,
      ),
      getCanonicalDriverBalanceUseCase: GetCanonicalDriverBalanceUseCase(
        driverBalanceRepository,
      ),
    );
  }
}
