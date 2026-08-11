import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/domain/value_objects/money.dart';
import '../../domain/entities/payment.dart';
import '../models/payment_model.dart';

extension PaymentModelMapper on PaymentModel {
  Payment toEntity() {
    final currency = CurrencyCode.tryParse(currencyCode);
    if (currency == null || amountMinorUnits <= 0) {
      throw const FormatException('Invalid persisted payment amount.');
    }

    return Payment(
      id: id,
      companyId: companyId,
      invoiceId: invoiceId,
      customerId: customerId,
      paymentMethodId: paymentMethodId,
      paymentDate: paymentDate,
      amount: Money(minorUnits: amountMinorUnits, currency: currency),
      referenceNumber: referenceNumber,
      notes: notes,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
