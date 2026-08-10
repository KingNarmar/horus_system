import '../../../../core/utils/result.dart';
import '../entities/payment_method.dart';
import '../entities/payment_method_write_data.dart';

abstract interface class PaymentMethodsRepository {
  Future<Result<List<PaymentMethod>>> getPaymentMethods({
    required String companyId,
  });

  Future<Result<List<PaymentMethod>>> getActivePaymentMethods({
    required String companyId,
  });

  Future<Result<PaymentMethod>> addPaymentMethod({
    required PaymentMethodWriteData data,
    required String actorRole,
  });

  Future<Result<PaymentMethod>> updatePaymentMethod({
    required String paymentMethodId,
    required PaymentMethodWriteData data,
    required String actorRole,
  });

  Future<Result<PaymentMethod>> deactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  });

  Future<Result<PaymentMethod>> reactivatePaymentMethod({
    required String companyId,
    required String paymentMethodId,
    required String actorRole,
  });
}
