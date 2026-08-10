import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/utils/result.dart';
import '../entities/payment.dart';

abstract interface class PaymentsRepository {
  Future<Result<List<Payment>>> getPayments({required String companyId});

  Future<Result<List<Payment>>> getPaymentsForInvoice({
    required String companyId,
    required String invoiceId,
  });

  Future<Result<Payment>> registerPayment({
    required String companyId,
    required String invoiceId,
    required String paymentMethodId,
    required DateTime paymentDate,
    required Money amount,
    String? referenceNumber,
    String? notes,
  });
}
