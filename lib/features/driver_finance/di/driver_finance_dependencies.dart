import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../data/datasources/canonical_driver_balance_remote_data_source.dart';
import '../data/datasources/driver_finance_remote_data_source.dart';
import '../data/repositories/driver_balance_repository_impl.dart';
import '../data/repositories/driver_finance_repository_impl.dart';
import '../domain/repositories/driver_balance_repository.dart';
import '../domain/repositories/driver_finance_repository.dart';
import '../domain/usecases/get_canonical_driver_balance_usecase.dart';

abstract final class DriverFinanceDependencies {
  static DriverFinanceRepository createRepository() {
    return DriverFinanceRepositoryImpl(
      remoteDataSource: SupabaseDriverFinanceRemoteDataSource(
        SupabaseClientProvider.client,
      ),
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static DriverBalanceRepository createBalanceRepository() {
    return DriverBalanceRepositoryImpl(
      remoteDataSource: SupabaseCanonicalDriverBalanceRemoteDataSource(
        SupabaseClientProvider.client,
      ),
    );
  }

  static GetCanonicalDriverBalanceUseCase
  createGetCanonicalDriverBalanceUseCase() {
    return GetCanonicalDriverBalanceUseCase(createBalanceRepository());
  }
}
