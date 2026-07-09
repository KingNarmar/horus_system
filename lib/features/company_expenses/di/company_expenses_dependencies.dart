import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/di/audit_dependencies.dart';
import '../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../data/datasources/company_expenses_remote_data_source.dart';
import '../data/repositories/company_expenses_repository_impl.dart';
import '../domain/repositories/company_expenses_repository.dart';
import '../domain/usecases/company_expenses_usecases.dart';
import '../presentation/cubit/company_expenses_cubit.dart';

abstract final class CompanyExpensesDependencies {
  static CompanyExpensesRemoteDataSource createRemoteDataSource() {
    return SupabaseCompanyExpensesRemoteDataSource(
      SupabaseClientProvider.client,
    );
  }

  static CompanyExpensesRepository createRepository({
    CreateAuditLogUseCase? createAuditLogUseCase,
  }) {
    return CompanyExpensesRepositoryImpl(
      remoteDataSource: createRemoteDataSource(),
      createAuditLogUseCase:
          createAuditLogUseCase ?? AuditDependencies.createAuditLogUseCase,
    );
  }

  static CompanyExpensesCubit createCubit() {
    final repository = createRepository();

    return CompanyExpensesCubit(
      getCategoriesUseCase: createGetCategoriesUseCase(repository),
      getExpensesUseCase: createGetExpensesUseCase(repository),
      getFormLookupsUseCase: createGetFormLookupsUseCase(repository),
      addExpenseUseCase: createAddExpenseUseCase(repository),
      updateExpenseUseCase: createUpdateExpenseUseCase(repository),
      voidExpenseUseCase: createVoidExpenseUseCase(repository),
      getEntityAuditLogsUseCase: AuditDependencies.getEntityAuditLogsUseCase,
    );
  }

  static GetCompanyExpenseCategoriesUseCase createGetCategoriesUseCase(
    CompanyExpensesRepository repository,
  ) {
    return GetCompanyExpenseCategoriesUseCase(repository);
  }

  static GetCompanyExpensesUseCase createGetExpensesUseCase(
    CompanyExpensesRepository repository,
  ) {
    return GetCompanyExpensesUseCase(repository);
  }

  static GetCompanyExpenseFormLookupsUseCase createGetFormLookupsUseCase(
    CompanyExpensesRepository repository,
  ) {
    return GetCompanyExpenseFormLookupsUseCase(repository);
  }

  static AddCompanyExpenseUseCase createAddExpenseUseCase(
    CompanyExpensesRepository repository,
  ) {
    return AddCompanyExpenseUseCase(repository);
  }

  static UpdateCompanyExpenseUseCase createUpdateExpenseUseCase(
    CompanyExpensesRepository repository,
  ) {
    return UpdateCompanyExpenseUseCase(repository);
  }

  static VoidCompanyExpenseUseCase createVoidExpenseUseCase(
    CompanyExpensesRepository repository,
  ) {
    return VoidCompanyExpenseUseCase(repository);
  }
}
