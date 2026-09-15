import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/repositories/expense_types_repository.dart';
import '../datasources/expense_types_remote_data_source.dart';
import '../mappers/expense_type_mapper.dart';
import 'expense_type_repository_failure_mapper.dart';

class ExpenseTypesRepositoryImpl implements ExpenseTypesRepository {
  final ExpenseTypesRemoteDataSource remoteDataSource;
  final ExpenseTypeRepositoryFailureMapper _failureMapper;

  const ExpenseTypesRepositoryImpl({required this.remoteDataSource})
    : _failureMapper = const ExpenseTypeRepositoryFailureMapper();

  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getExpenseTypes(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<ExpenseType>>> getActiveExpenseTypes({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getActiveExpenseTypes(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  @override
  Future<Result<List<ExpenseType>>> getLedgerEligibleExpenseTypes({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getLedgerEligibleExpenseTypes(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    });
  }

  Future<Result<T>> _guard<T>(Future<Result<T>> Function() action) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        _failureMapper.fromPostgrest(
          error,
          permissionCode: FailureCodes.permissionExpenseTypesView,
        ),
      );
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
