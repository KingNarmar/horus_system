import '../../../../core/utils/result.dart';
import '../entities/customer_statement_source.dart';

abstract interface class CustomerStatementsRepository {
  Future<Result<CustomerStatementSource>> getStatementSource({
    required String companyId,
    required String customerId,
    DateTime? fromDate,
    DateTime? toDate,
  });
}
