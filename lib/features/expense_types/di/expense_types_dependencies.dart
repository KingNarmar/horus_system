import '../../../core/data/supabase/supabase_client_provider.dart';
import '../data/datasources/expense_types_remote_data_source.dart';
import '../data/repositories/expense_types_repository_impl.dart';
import '../domain/repositories/expense_types_repository.dart';
import '../domain/usecases/get_active_expense_types_usecase.dart';
import '../domain/usecases/get_expense_type_catalog_usecase.dart';
import '../domain/usecases/get_ledger_eligible_expense_types_usecase.dart';
import '../presentation/cubit/expense_types_cubit.dart';

abstract final class ExpenseTypesDependencies {
  static ExpenseTypesRepository createRepository() {
    final remoteDataSource = SupabaseExpenseTypesRemoteDataSource(
      SupabaseClientProvider.client,
    );
    return ExpenseTypesRepositoryImpl(remoteDataSource: remoteDataSource);
  }

  static ExpenseTypesCubit createCubit() {
    final repository = createRepository();
    return ExpenseTypesCubit(
      getExpenseTypeCatalogUseCase: GetExpenseTypeCatalogUseCase(repository),
    );
  }

  static GetActiveExpenseTypesUseCase createGetActiveExpenseTypesUseCase() {
    return GetActiveExpenseTypesUseCase(createRepository());
  }

  static GetExpenseTypeCatalogUseCase createGetExpenseTypeCatalogUseCase() {
    return GetExpenseTypeCatalogUseCase(createRepository());
  }

  static GetLedgerEligibleExpenseTypesUseCase
  createGetLedgerEligibleExpenseTypesUseCase() {
    return GetLedgerEligibleExpenseTypesUseCase(createRepository());
  }
}
