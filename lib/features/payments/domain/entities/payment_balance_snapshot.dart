import '../../../../core/domain/value_objects/money.dart';
import '../../../invoices/domain/entities/invoice_status.dart';

final class PaymentBalanceInvoiceSnapshot {
  final String companyId;
  final String invoiceId;
  final InvoiceStatus status;
  final Money total;

  const PaymentBalanceInvoiceSnapshot({
    required this.companyId,
    required this.invoiceId,
    required this.status,
    required this.total,
  });
}

final class PaymentBalancePaymentSnapshot {
  final String companyId;
  final String invoiceId;
  final Money amount;

  const PaymentBalancePaymentSnapshot({
    required this.companyId,
    required this.invoiceId,
    required this.amount,
  });
}
