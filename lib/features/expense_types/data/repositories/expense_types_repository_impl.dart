import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../audit/domain/usecases/create_audit_log_usecase.dart';
import '../../domain/entities/expense_type.dart';
import '../../domain/entities/expense_type_write_data.dart';
import '../../domain/repositories/expense_types_repository.dart';
import '../datasources/expense_types_remote_data_source.dart';
import '../mappers/expense_type_mapper.dart';
import 'expense_type_repository_audit_writer.dart';
import 'expense_type_repository_failure_mapper.dart';

class ExpenseTypesRepositoryImpl implements ExpenseTypesRepository {
  final ExpenseTypesRemoteDataSource remoteDataSource;
  final CreateAuditLogUseCase createAuditLogUseCase;
  final ExpenseTypeRepositoryFailureMapper _failureMapper;

  const ExpenseTypesRepositoryImpl({
    required this.remoteDataSource,
    required this.createAuditLogUseCase,
  }) : _failureMapper = const ExpenseTypeRepositoryFailureMapper();

  ExpenseTypeRepositoryAuditWriter get _auditWriter {
    return ExpenseTypeRepositoryAuditWriter(createAuditLogUseCase);
  }

  @override
  Future<Result<List<ExpenseType>>> getExpenseTypes({
    required String companyId,
  }) {
    return _guard(() async {
      final models = await remoteDataSource.getExpenseTypes(
        companyId: companyId,
      );
      return Success(models.map((model) => model.toEntity()).toList());
    }, permissionCode: FailureCodes.permissionExpenseTypesManagement);
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
    }, permissionCode: FailureCodes.permissionExpenseTypesView);
  }

  @override
  Future<Result<ExpenseType>> addExpenseType({
    required ExpenseTypeWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final model = await remoteDataSource.addExpenseType(data: data);
      final auditFailure = await _auditWriter.writeCreated(
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) return FailureResult<ExpenseType>(auditFailure);
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionExpenseTypesManagement);
  }

  @override
  Future<Result<ExpenseType>> updateExpenseType({
    required String expenseTypeId,
    required ExpenseTypeWriteData data,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getExpenseTypeById(
        companyId: data.companyId,
        expenseTypeId: expenseTypeId,
      );
      final model = await remoteDataSource.updateExpenseType(
        expenseTypeId: expenseTypeId,
        data: data,
      );
      final auditFailure = await _auditWriter.writeUpdated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) return FailureResult<ExpenseType>(auditFailure);
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionExpenseTypesManagement);
  }

  @override
  Future<Result<ExpenseType>> deactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getExpenseTypeById(
        companyId: companyId,
        expenseTypeId: expenseTypeId,
      );
      final model = await remoteDataSource.deactivateExpenseType(
        companyId: companyId,
        expenseTypeId: expenseTypeId,
      );
      final auditFailure = await _auditWriter.writeDeactivated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) return FailureResult<ExpenseType>(auditFailure);
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionExpenseTypesManagement);
  }

  @override
  Future<Result<ExpenseType>> reactivateExpenseType({
    required String companyId,
    required String expenseTypeId,
    required String actorRole,
  }) {
    return _guard(() async {
      final oldModel = await remoteDataSource.getExpenseTypeById(
        companyId: companyId,
        expenseTypeId: expenseTypeId,
      );
      final model = await remoteDataSource.reactivateExpenseType(
        companyId: companyId,
        expenseTypeId: expenseTypeId,
      );
      final auditFailure = await _auditWriter.writeReactivated(
        oldModel: oldModel,
        model: model,
        actorRole: actorRole,
      );
      if (auditFailure != null) return FailureResult<ExpenseType>(auditFailure);
      return Success(model.toEntity());
    }, permissionCode: FailureCodes.permissionExpenseTypesManagement);
  }

  Future<Result<T>> _guard<T>(
    Future<Result<T>> Function() action, {
    required String permissionCode,
  }) async {
    try {
      return await action();
    } on PostgrestException catch (error) {
      return FailureResult(
        _failureMapper.fromPostgrest(error, permissionCode: permissionCode),
      );
    } catch (error) {
      return FailureResult(_failureMapper.fromUnexpected(error));
    }
  }
}
