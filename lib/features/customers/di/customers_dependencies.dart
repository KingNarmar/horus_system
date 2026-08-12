import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../data/datasources/customers_remote_data_source.dart';
import '../data/repositories/customers_repository_impl.dart';
import '../domain/repositories/customers_repository.dart';
import '../domain/usecases/add_customer_usecase.dart';
import '../domain/usecases/deactivate_customer_usecase.dart';
import '../domain/usecases/get_customers_usecase.dart';
import '../domain/usecases/reactivate_customer_usecase.dart';
import '../domain/usecases/update_customer_usecase.dart';
import '../presentation/cubit/customers_cubit.dart';

abstract final class CustomersDependencies {
  static CustomersRepository createRepository() {
    return CustomersRepositoryImpl(
      remoteDataSource: SupabaseCustomersRemoteDataSource(
        SupabaseClientProvider.client,
      ),
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static GetCustomersUseCase createGetCustomersUseCase() {
    return GetCustomersUseCase(createRepository());
  }

  static CustomersCubit createCubit() {
    final repository = createRepository();
    return CustomersCubit(
      getCustomersUseCase: GetCustomersUseCase(repository),
      addCustomerUseCase: AddCustomerUseCase(repository),
      updateCustomerUseCase: UpdateCustomerUseCase(repository),
      deactivateCustomerUseCase: DeactivateCustomerUseCase(repository),
      reactivateCustomerUseCase: ReactivateCustomerUseCase(repository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
    );
  }
}
