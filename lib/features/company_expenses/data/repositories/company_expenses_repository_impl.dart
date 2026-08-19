import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/company_expense.dart';
import '../../domain/entities/company_expense_category.dart';
import '../../domain/entities/company_expense_form_lookups.dart';
import '../../domain/entities/company_expense_void_data.dart';
import '../../domain/entities/company_expense_write_data.dart';
import '../../domain/repositories/company_expenses_repository.dart';
import '../datasources/company_expenses_remote_data_source.dart';
import '../mappers/company_expense_category_mapper.dart';
import '../mappers/company_expense_form_lookups_mapper.dart';
import '../mappers/company_expense_mapper.dart';
import 'company_expense_repository_audit_writer.dart';
import 'company_expense_repository_failure_mapper.dart';

class CompanyExpensesRepositoryImpl implements CompanyExpensesRepository {
  final CompanyExpensesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final CompanyExpenseRepositoryFailureMapper _failureMapper;

  const CompanyExpensesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const CompanyExpenseRepositoryFailureMapper();

  CompanyExpenseRepositoryAuditWriter get _auditWriter {
    return CompanyExpenseRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<CompanyExpenseCategory>>> getCategories({
    required String companyId,
    bool includeInactive = false,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getCategories(
        companyId: companyId,
        includeInactive: includeInactive,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<CompanyExpense>>> getCompanyExpenses({
    required String companyId,
    bool includeVoided = false,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getCompanyExpenses(
        companyId: companyId,
        includeVoided: includeVoided,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<CompanyExpenseFormLookups>> getFormLookups({
    required String companyId,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.getFormLookups(companyId: companyId);
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<CompanyExpense>> addCompanyExpense({
    required CompanyExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addCompanyExpense(data: data);
      final auditFailure = await _auditWriter.writeCreated(
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<CompanyExpense>(auditFailure);
      }

      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<CompanyExpense>> updateCompanyExpense({
    required String id,
    required CompanyExpenseWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCompanyExpenseById(
        companyId: data.companyId,
        id: id,
      );
      final model = await remoteDataSource.updateCompanyExpense(
        id: id,
        data: data,
      );
      final auditFailure = await _auditWriter.writeUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<CompanyExpense>(auditFailure);
      }

      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<CompanyExpense>> voidCompanyExpense({
    required CompanyExpenseVoidData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getCompanyExpenseById(
        companyId: data.companyId,
        id: data.expenseId,
      );
      final model = await remoteDataSource.voidCompanyExpense(data: data);
      final auditFailure = await _auditWriter.writeVoided(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );

      if (auditFailure != null) {
        return FailureResult<CompanyExpense>(auditFailure);
      }

      return Success(model.toEntity());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(_failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
