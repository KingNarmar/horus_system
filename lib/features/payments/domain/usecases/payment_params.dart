import '../../../company/domain/entities/current_company_context.dart';

final class GetPaymentsParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetPaymentsParams({required this.currentCompanyContext});
}

final class GetPayableInvoicesParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetPayableInvoicesParams({required this.currentCompanyContext});
}

final class GetPaymentBusinessDateParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetPaymentBusinessDateParams({required this.currentCompanyContext});
}

final class RegisterPaymentParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;
  final String paymentMethodId;
  final DateTime paymentDate;
  final String amountText;
  final String? referenceNumber;
  final String? notes;

  const RegisterPaymentParams({
    required this.currentCompanyContext,
    required this.invoiceId,
    required this.paymentMethodId,
    required this.paymentDate,
    required this.amountText,
    this.referenceNumber,
    this.notes,
  });
}
