import '../../../invoices/domain/entities/invoice.dart';
import 'payment_balance.dart';

final class PayableInvoice {
  final Invoice invoice;
  final PaymentBalance balance;

  const PayableInvoice({required this.invoice, required this.balance});
}
