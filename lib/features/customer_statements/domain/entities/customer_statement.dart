import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'customer_statement_line.dart';

final class CustomerStatement {
  final String companyId;
  final String customerId;
  final String customerName;
  final bool customerIsActive;
  final CurrencyCode currency;
  final int fractionDigits;
  final String businessTimezone;
  final DateTime? fromDate;
  final DateTime? toDate;
  final Money openingBalance;
  final Money totalInvoiced;
  final Money totalPaid;
  final Money closingBalance;
  final List<CustomerStatementLine> lines;

  const CustomerStatement({
    required this.companyId,
    required this.customerId,
    required this.customerName,
    required this.customerIsActive,
    required this.currency,
    required this.fractionDigits,
    required this.businessTimezone,
    required this.fromDate,
    required this.toDate,
    required this.openingBalance,
    required this.totalInvoiced,
    required this.totalPaid,
    required this.closingBalance,
    required this.lines,
  });
}
