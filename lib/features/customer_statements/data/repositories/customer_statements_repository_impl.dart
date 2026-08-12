import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../domain/entities/customer_statement_source.dart';
import '../../domain/repositories/customer_statements_repository.dart';
import '../datasources/customer_statements_remote_data_source.dart';
import '../mappers/customer_statement_mapper.dart';
import '../mappers/customer_statements_failure_mapper.dart';

final class CustomerStatementsRepositoryImpl
    implements CustomerStatementsRepository {
  final CustomerStatementsRemoteDataSource _remoteDataSource;

  const CustomerStatementsRepositoryImpl(this._remoteDataSource);

  @override
  Future<Result<CustomerStatementSource>> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      final model = await _remoteDataSource.getStatementSource(
        companyId: companyId,
        customerId: customerId,
        fromDate: fromDate,
        toDate: toDate,
      );
      return Success(model.toEntity());
    } on AuthException {
      return const FailureResult(
        AuthFailure(code: CompanyFailureCodes.authRequired),
      );
    } on PostgrestException catch (error) {
      return FailureResult(
        CustomerStatementsFailureMapper.fromPostgrest(error),
      );
    } on FormatException {
      return const FailureResult(ServerFailure(code: FailureCodes.serverError));
    } catch (_) {
      return const FailureResult(UnexpectedFailure());
    }
  }
}
