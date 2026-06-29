import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../data/datasources/company_expenses_remote_data_source.dart';
import '../data/repositories/company_expenses_repository_impl.dart';
import '../domain/repositories/company_expenses_repository.dart';
import '../domain/usecases/company_expenses_usecases.dart';

abstract final class CompanyExpensesDependencies {
  static CompanyExpensesRemoteDataSource createRemoteDataSource() {
    return SupabaseCompanyExpensesRemoteDataSource(
      SupabaseClientProvider.client,
    );
  }

  static CompanyExpensesRepository createRepository({
    required CreateAuditLogUseCase createAuditLogUseCase,
  }) {
    return CompanyExpensesRepositoryImpl(
      remoteDataSource: createRemoteDataSource(),
      createAuditLogUseCase: createAuditLogUseCase,
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
