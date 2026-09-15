import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import '../../../../core/utils/result.dart';
import '../../domain/entities/expense_ledger_entry.dart';
import '../../domain/entities/expense_ledger_write_data.dart';
import '../../domain/repositories/expense_ledger_repository.dart';
import '../datasources/expense_ledger_remote_data_source.dart';
import '../mappers/expense_ledger_mapper.dart';
import 'expense_ledger_repository_failure_mapper.dart';

final class ExpenseLedgerRepositoryImpl implements ExpenseLedgerRepository {
  final ExpenseLedgerRemoteDataSource remoteDataSource;
  final ExpenseLedgerRepositoryFailureMapper failureMapper;

  const ExpenseLedgerRepositoryImpl({
    required this.remoteDataSource,
    this.failureMapper = const ExpenseLedgerRepositoryFailureMapper(),
  });

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntries({
    required String companyId,
    bool includeVoided = false,
  }) async {
    try {
      final models = await remoteDataSource.getEntries(
        companyId: companyId,
        includeVoided: includeVoided,
      );
      return Success(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } on PostgrestException catch (error) {
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<List<ExpenseLedgerEntry>>> getEntriesForTrip({
    required String companyId,
    required String tripId,
    bool includeVoided = false,
  }) async {
    try {
      final models = await remoteDataSource.getEntriesForTrip(
        companyId: companyId,
        tripId: tripId,
        includeVoided: includeVoided,
      );
      return Success(
        models.map((model) => model.toEntity()).toList(growable: false),
      );
    } on PostgrestException catch (error) {
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<ExpenseLedgerEntry>> createEntry(
    ExpenseLedgerWriteData data,
  ) async {
    try {
      final model = await remoteDataSource.createEntry(data);
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }

  @override
  Future<Result<ExpenseLedgerEntry>> voidEntry({
    required String companyId,
    required String expenseId,
    String? reason,
  }) async {
    try {
      final model = await remoteDataSource.voidEntry(
        companyId: companyId,
        expenseId: expenseId,
        reason: reason,
      );
      return Success(model.toEntity());
    } on PostgrestException catch (error) {
      return FailureResult(failureMapper.fromPostgrest(error));
    } catch (error) {
      return FailureResult(failureMapper.fromUnexpected(error));
    }
  }
}
