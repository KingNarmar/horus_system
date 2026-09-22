import '../../../core/data/services/timezone_business_time_zone_converter.dart';
import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../../core/usecases/get_company_business_date_usecase.dart';
import '../../company/di/company_dependencies.dart';
import '../../drivers/di/drivers_dependencies.dart';
import '../../audit/di/audit_dependencies.dart';
import '../data/datasources/canonical_driver_balance_remote_data_source.dart';
import '../data/datasources/driver_finance_remote_data_source.dart';
import '../data/repositories/driver_balance_repository_impl.dart';
import '../data/repositories/driver_finance_repository_impl.dart';
import '../domain/repositories/driver_balance_repository.dart';
import '../domain/repositories/driver_finance_repository.dart';
import '../domain/repositories/driver_money_balance_repository.dart';
import '../domain/usecases/can_manage_driver_finance_usecase.dart';
import '../domain/usecases/get_canonical_driver_balance_usecase.dart';
import '../domain/usecases/driver_finance_usecases.dart';
import '../domain/usecases/get_canonical_driver_money_balance_usecase.dart';
import '../presentation/cubit/driver_finance_cubit.dart';

abstract final class DriverFinanceDependencies {
  static DriverFinanceCubit createCubit() {
    final repository = createRepository();
    final getCompanyBusinessDateUseCase = GetCompanyBusinessDateUseCase(
      CompanyDependencies.createBusinessDateProvider(),
    );

    return DriverFinanceCubit(
      getDriversUseCase: DriversDependencies.createGetDriversUseCase(),
      canManageDriverFinanceUseCase: const CanManageDriverFinanceUseCase(),
      getCompanyBusinessDateUseCase: getCompanyBusinessDateUseCase,
      getDriverMovementsUseCase: GetDriverMovementsUseCase(repository),
      getDriverTripOptionsUseCase: GetDriverTripOptionsUseCase(repository),
      addDriverAdvanceUseCase: AddDriverAdvanceUseCase(repository),
      addDriverChargeUseCase: AddDriverChargeUseCase(repository),
      addDriverCashReturnUseCase: AddDriverCashReturnUseCase(repository),
      getCurrentCanonicalDriverBalanceUseCase:
          createGetCurrentCanonicalDriverBalanceUseCase(
            getCompanyBusinessDateUseCase: getCompanyBusinessDateUseCase,
          ),
    );
  }

  static DriverFinanceRepository createRepository() {
    return DriverFinanceRepositoryImpl(
      remoteDataSource: SupabaseDriverFinanceRemoteDataSource(
        SupabaseClientProvider.client,
        businessTimeZoneConverter: const TimezoneBusinessTimeZoneConverter(),
      ),
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static DriverBalanceRepositoryImpl _createBalanceRepositoryImpl() {
    return DriverBalanceRepositoryImpl(
      remoteDataSource: SupabaseCanonicalDriverBalanceRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static DriverBalanceRepository createBalanceRepository() {
    return _createBalanceRepositoryImpl();
  }

  static DriverMoneyBalanceRepository createMoneyBalanceRepository() {
    return _createBalanceRepositoryImpl();
  }

  static GetCanonicalDriverBalanceUseCase
  createGetCanonicalDriverBalanceUseCase() {
    return GetCanonicalDriverBalanceUseCase(createBalanceRepository());
  }

  static GetCanonicalDriverMoneyBalanceUseCase
  createGetCanonicalDriverMoneyBalanceUseCase() {
    return GetCanonicalDriverMoneyBalanceUseCase(
      createMoneyBalanceRepository(),
    );
  }

  static GetCurrentCanonicalDriverBalanceUseCase
  createGetCurrentCanonicalDriverBalanceUseCase({
    required GetCompanyBusinessDateUseCase getCompanyBusinessDateUseCase,
  }) {
    return GetCurrentCanonicalDriverBalanceUseCase(
      getCompanyBusinessDateUseCase: getCompanyBusinessDateUseCase,
      getCanonicalDriverBalanceUseCase:
          createGetCanonicalDriverBalanceUseCase(),
    );
  }
}
