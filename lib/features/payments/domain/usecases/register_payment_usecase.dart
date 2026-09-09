import '../../../../core/domain/services/company_business_date_provider.dart';
import '../../../../core/domain/value_objects/business_date.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../../company/domain/policies/company_financial_readiness_policy.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../invoices/domain/repositories/invoices_repository.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/repositories/payment_methods_repository.dart';
import '../entities/payment.dart';
import '../entities/payment_balance.dart';
import '../failures/payment_failure_codes.dart';
import '../policies/payments_permission_policy.dart';
import '../repositories/payments_repository.dart';
import '../services/payment_amount_parser.dart';
import '../services/payment_balance_calculator.dart';
import 'payment_params.dart';

final class RegisterPaymentUseCase
    implements UseCase<Payment, RegisterPaymentParams> {
  final PaymentsRepository _paymentsRepository;
  final InvoicesRepository _invoicesRepository;
  final PaymentMethodsRepository _paymentMethodsRepository;
  final CompanyBusinessDateProvider _businessDateProvider;
  final PaymentBalanceCalculator _balanceCalculator;

  const RegisterPaymentUseCase({
    required PaymentsRepository paymentsRepository,
    required InvoicesRepository invoicesRepository,
    required PaymentMethodsRepository paymentMethodsRepository,
    required CompanyBusinessDateProvider businessDateProvider,
    PaymentBalanceCalculator balanceCalculator =
        const PaymentBalanceCalculator(),
  }) : _paymentsRepository = paymentsRepository,
       _invoicesRepository = invoicesRepository,
       _paymentMethodsRepository = paymentMethodsRepository,
       _businessDateProvider = businessDateProvider,
       _balanceCalculator = balanceCalculator;

  @override
  Future<Result<Payment>> call(RegisterPaymentParams params) async {
    final context = params.currentCompanyContext;
    if (!PaymentsPermissionPolicy.canRegisterPayments(context.role)) {
      return const FailureResult<Payment>(
        PermissionFailure(code: PaymentFailureCodes.permissionManage),
      );
    }

    final invoiceId = _required(params.invoiceId);
    if (invoiceId == null) {
      return const FailureResult<Payment>(
        ValidationFailure(
          code: PaymentFailureCodes.validationInvoiceIdRequired,
        ),
      );
    }

    final paymentMethodId = _required(params.paymentMethodId);
    if (paymentMethodId == null) {
      return const FailureResult<Payment>(
        ValidationFailure(
          code: PaymentFailureCodes.validationPaymentMethodIdRequired,
        ),
      );
    }

    final readiness = CompanyFinancialReadinessPolicy.evaluate(context.company);
    final configuration = readiness.configuration;
    if (!readiness.isReady || configuration == null) {
      return const FailureResult<Payment>(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }

    final invoiceResult = await _invoicesRepository.getInvoiceDetails(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
    if (invoiceResult is FailureResult<Invoice>) {
      return FailureResult<Payment>(invoiceResult.failure);
    }
    final invoice = (invoiceResult as Success<Invoice>).data;

    if (invoice.status != InvoiceStatus.issued &&
        invoice.status != InvoiceStatus.partiallyPaid) {
      return const FailureResult<Payment>(
        ConflictFailure(code: PaymentFailureCodes.conflictInvoiceStatusInvalid),
      );
    }

    if (invoice.currency != configuration.baseCurrency) {
      return const FailureResult<Payment>(
        ValidationFailure(code: PaymentFailureCodes.validationCurrencyMismatch),
      );
    }

    final amount = PaymentAmountParser.tryParse(
      rawValue: params.amountText,
      currency: invoice.currency,
      fractionDigits: configuration.fractionDigits,
    );
    if (amount == null) {
      return const FailureResult<Payment>(
        ValidationFailure(code: PaymentFailureCodes.validationAmountInvalid),
      );
    }
    if (!amount.isPositive) {
      return const FailureResult<Payment>(
        ValidationFailure(code: PaymentFailureCodes.validationAmountPositive),
      );
    }

    final issueDate = invoice.issueDate?.value;
    if (issueDate == null) {
      return const FailureResult<Payment>(
        ConflictFailure(
          code: PaymentFailureCodes.conflictInvoiceBalanceInvalid,
        ),
      );
    }

    final paymentDate = params.paymentDate;
    if (paymentDate.isBefore(issueDate)) {
      return const FailureResult<Payment>(
        ValidationFailure(
          code: PaymentFailureCodes.validationDateBeforeInvoice,
        ),
      );
    }

    final businessDateResult = await _businessDateProvider.getBusinessDate(
      companyId: context.companyId,
    );
    if (businessDateResult is FailureResult<BusinessDate>) {
      return FailureResult<Payment>(businessDateResult.failure);
    }
    final businessDate = (businessDateResult as Success<BusinessDate>).data;
    if (paymentDate.isAfter(businessDate)) {
      return const FailureResult<Payment>(
        ValidationFailure(code: PaymentFailureCodes.validationDateFuture),
      );
    }

    final methodsResult = await _paymentMethodsRepository.getPaymentMethods(
      companyId: context.companyId,
    );
    if (methodsResult is FailureResult<List<PaymentMethod>>) {
      return FailureResult<Payment>(methodsResult.failure);
    }
    final methods = (methodsResult as Success<List<PaymentMethod>>).data;
    PaymentMethod? selectedMethod;
    for (final method in methods) {
      if (method.id == paymentMethodId) {
        selectedMethod = method;
        break;
      }
    }
    if (selectedMethod == null) {
      return const FailureResult<Payment>(
        NotFoundFailure(code: PaymentFailureCodes.paymentMethodNotFound),
      );
    }
    if (!selectedMethod.isActive) {
      return const FailureResult<Payment>(
        ConflictFailure(
          code: PaymentFailureCodes.conflictPaymentMethodInactive,
        ),
      );
    }

    final paymentsResult = await _paymentsRepository.getPaymentsForInvoice(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
    if (paymentsResult is FailureResult<List<Payment>>) {
      return FailureResult<Payment>(paymentsResult.failure);
    }

    final balanceResult = _balanceCalculator.calculate(
      invoice: invoice,
      payments: (paymentsResult as Success<List<Payment>>).data,
    );
    if (balanceResult is FailureResult<PaymentBalance>) {
      return FailureResult<Payment>(balanceResult.failure);
    }
    final balance = (balanceResult as Success<PaymentBalance>).data;
    if (amount.minorUnits > balance.remaining.minorUnits) {
      return const FailureResult<Payment>(
        ConflictFailure(code: PaymentFailureCodes.conflictOverpayment),
      );
    }

    return _paymentsRepository.registerPayment(
      companyId: context.companyId,
      invoiceId: invoiceId,
      paymentMethodId: paymentMethodId,
      paymentDate: paymentDate,
      amount: amount,
      referenceNumber: _optional(params.referenceNumber),
      notes: _optional(params.notes),
    );
  }
}

String? _required(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? null : normalized;
}

String? _optional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
