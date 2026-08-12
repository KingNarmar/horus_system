import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import 'customer_statement_movement.dart';

final class CustomerStatementSource {
  final String companyId;
  final String customerId;
  final String customerName;
  final bool customerIsActive;
  final CurrencyCode baseCurrency;
  final int baseCurrencyFractionDigits;
  final String businessTimezone;
  final DateTime? fromDate;
  final DateTime? toDate;
  final List<Money> openingInvoiceAmounts;
  final List<Money> openingPaymentAmounts;
  final List<CustomerStatementMovement> movements;

  const CustomerStatementSource({
    required this.companyId,
    required this.customerId,
    required this.customerName,
    required this.customerIsActive,
    required this.baseCurrency,
    required this.baseCurrencyFractionDigits,
    required this.businessTimezone,
    required this.fromDate,
    required this.toDate,
    required this.openingInvoiceAmounts,
    required this.openingPaymentAmounts,
    required this.movements,
  });
}
