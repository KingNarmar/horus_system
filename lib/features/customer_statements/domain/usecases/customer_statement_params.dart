import '../../../company/domain/entities/current_company_context.dart';

final class GetCustomerStatementParams {
  final CurrentCompanyContext currentCompanyContext;
  final String customerId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const GetCustomerStatementParams({
    required this.currentCompanyContext,
    required this.customerId,
    this.fromDate,
    this.toDate,
  });
}
