import '../../../core/data/supabase/supabase_client_provider.dart';
import '../../audit/data/datasources/audit_logs_remote_data_source.dart';
import '../../audit/data/repositories/audit_log_repository_impl.dart';
import '../../audit/domain/repositories/audit_log_repository.dart';
import '../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../data/datasources/company_expenses_remote_data_source.dart';
import '../data/repositories/company_expenses_repository_impl.dart';
import '../domain/repositories/company_expenses_repository.dart';
import '../domain/usecases/company_expenses_usecases.dart';
import '../presentation/cubit/company_expenses_cubit.dart';

abstract final class CompanyExpensesDependencies {
  static AuditLogsRemoteDataSource? _auditLogsRemoteDataSourceInstance;
  static AuditLogsRemoteDataSource get _auditLogsRemoteDataSource =>
      _auditLogsRemoteDataSourceInstance ??= SupabaseAuditLogsRemoteDataSource(
        SupabaseClientProvider.client,
      );

  static AuditLogRepository? _auditLogRepositoryInstance;
  static AuditLogRepository get _auditLogRepository =>
      _auditLogRepositoryInstance ??= AuditLogRepositoryImpl(
        remoteDataSource: _auditLogsRemoteDataSource,
      );

  static CreateAuditLogUseCase? _createAuditLogUseCaseInstance;
  static CreateAuditLogUseCase get _createAuditLogUseCase =>
      _createAuditLogUseCaseInstance ??= CreateAuditLogUseCase(
        _auditLogRepository,
      );

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
      createAuditLogUseCase: createAuditLogUseCase ?? _createAuditLogUseCase,
    );
  }

  static CompanyExpensesCubit createCubit() {
    final repository = createRepository();

    return CompanyExpensesCubit(
      getCategoriesUseCase: createGetCategoriesUseCase(repository),
      getExpensesUseCase: createGetExpensesUseCase(repository),
      addExpenseUseCase: createAddExpenseUseCase(repository),
      updateExpenseUseCase: createUpdateExpenseUseCase(repository),
      voidExpenseUseCase: createVoidExpenseUseCase(repository),
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
