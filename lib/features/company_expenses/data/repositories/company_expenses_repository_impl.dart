import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
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
import 'company_expense_repository_failure_mapper.dart';

class CompanyExpensesRepositoryImpl implements CompanyExpensesRepository {
  final CompanyExpensesRemoteDataSource remoteDataSource;
  final CompanyExpenseRepositoryFailureMapper _failureMapper;

  const CompanyExpensesRepositoryImpl({required this.remoteDataSource})
    : _failureMapper = const CompanyExpenseRepositoryFailureMapper();

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
      final model = await remoteDataSource.updateCompanyExpense(
        id: id,
        data: data,
      );
      return Success(model.toEntity());
    });
  }

  @override
  Future<Result<CompanyExpense>> voidCompanyExpense({
    required CompanyExpenseVoidData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.voidCompanyExpense(data: data);
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
