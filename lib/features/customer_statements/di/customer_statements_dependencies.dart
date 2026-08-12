import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../customers/di/customers_dependencies.dart';
import '../data/datasources/customer_statements_remote_data_source.dart';
import '../data/repositories/customer_statements_repository_impl.dart';
import '../domain/repositories/customer_statements_repository.dart';
import '../domain/usecases/get_customer_statement_usecase.dart';
import '../presentation/cubit/customer_statements_cubit.dart';

abstract final class CustomerStatementsDependencies {
  static CustomerStatementsRepository createRepository() {
    return CustomerStatementsRepositoryImpl(
      SupabaseCustomerStatementsRemoteDataSource(SupabaseClientProvider.client),
    );
  }

  static CustomerStatementsCubit createCubit() {
    return CustomerStatementsCubit(
      getCustomersUseCase: CustomersDependencies.createGetCustomersUseCase(),
      getCustomerStatementUseCase: GetCustomerStatementUseCase(
        repository: createRepository(),
      ),
    );
  }
}
