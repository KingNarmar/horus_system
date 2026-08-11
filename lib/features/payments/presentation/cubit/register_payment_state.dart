import '../../../../core/errors/failure.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../domain/entities/payable_invoice.dart';
import '../../domain/entities/payment.dart';

sealed class RegisterPaymentState {
  const RegisterPaymentState();
}

final class RegisterPaymentInitial extends RegisterPaymentState {
  const RegisterPaymentInitial();
}

final class RegisterPaymentLoading extends RegisterPaymentState {
  const RegisterPaymentLoading();
}

final class RegisterPaymentFailure extends RegisterPaymentState {
  final Failure failure;

  const RegisterPaymentFailure(this.failure);
}

final class RegisterPaymentReady extends RegisterPaymentState {
  static const Object _unset = Object();

  final CurrentCompanyContext currentCompanyContext;
  final List<PayableInvoice> payableInvoices;
  final List<PaymentMethod> paymentMethods;
  final DateTime businessDate;
  final bool isSubmitting;
  final Failure? submissionFailure;
  final Payment? completedPayment;
  final int feedbackSequence;

  const RegisterPaymentReady({
    required this.currentCompanyContext,
    required this.payableInvoices,
    required this.paymentMethods,
    required this.businessDate,
    this.isSubmitting = false,
    this.submissionFailure,
    this.completedPayment,
    this.feedbackSequence = 0,
  });

  bool get canSubmit =>
      payableInvoices.isNotEmpty && paymentMethods.isNotEmpty && !isSubmitting;

  RegisterPaymentReady copyWith({
    bool? isSubmitting,
    Object? submissionFailure = _unset,
    Object? completedPayment = _unset,
    int? feedbackSequence,
  }) {
    return RegisterPaymentReady(
      currentCompanyContext: currentCompanyContext,
      payableInvoices: payableInvoices,
      paymentMethods: paymentMethods,
      businessDate: businessDate,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submissionFailure: identical(submissionFailure, _unset)
          ? this.submissionFailure
          : submissionFailure as Failure?,
      completedPayment: identical(completedPayment, _unset)
          ? this.completedPayment
          : completedPayment as Payment?,
      feedbackSequence: feedbackSequence ?? this.feedbackSequence,
    );
  }
}
