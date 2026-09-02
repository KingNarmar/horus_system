import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../data/datasources/expense_types_remote_data_source.dart';
import '../data/repositories/expense_types_repository_impl.dart';
import '../domain/repositories/expense_types_repository.dart';
import '../domain/usecases/add_expense_type_usecase.dart';
import '../domain/usecases/deactivate_expense_type_usecase.dart';
import '../domain/usecases/get_active_expense_types_usecase.dart';
import '../domain/usecases/get_expense_types_usecase.dart';
import '../domain/usecases/reactivate_expense_type_usecase.dart';
import '../domain/usecases/update_expense_type_usecase.dart';
import '../presentation/cubit/expense_types_cubit.dart';

abstract final class ExpenseTypesDependencies {
  static ExpenseTypesRepository createRepository() {
    final remoteDataSource = SupabaseExpenseTypesRemoteDataSource(
      SupabaseClientProvider.client,
    );
    return ExpenseTypesRepositoryImpl(
      remoteDataSource: remoteDataSource,
      createAuditLogUseCase: AuditDependencies.createAuditLogUseCase,
    );
  }

  static ExpenseTypesCubit createCubit() {
    final repository = createRepository();
    return ExpenseTypesCubit(
      getExpenseTypesUseCase: GetExpenseTypesUseCase(repository),
      addExpenseTypeUseCase: AddExpenseTypeUseCase(repository),
      updateExpenseTypeUseCase: UpdateExpenseTypeUseCase(repository),
      deactivateExpenseTypeUseCase: DeactivateExpenseTypeUseCase(repository),
      reactivateExpenseTypeUseCase: ReactivateExpenseTypeUseCase(repository),
    );
  }

  static GetActiveExpenseTypesUseCase createGetActiveExpenseTypesUseCase() {
    return GetActiveExpenseTypesUseCase(createRepository());
  }
}
