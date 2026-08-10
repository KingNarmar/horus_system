import '../../../../core/domain/services/company_business_date_provider.dart';
import '../../../../core/domain/value_objects/currency_code.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/failures/company_failure_codes.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../invoices/domain/repositories/invoices_repository.dart';
import '../../../payment_methods/domain/entities/payment_method.dart';
import '../../../payment_methods/domain/repositories/payment_methods_repository.dart';
import '../entities/payable_invoice.dart';
import '../entities/payment.dart';
import '../entities/payment_balance.dart';
import '../failures/payment_failure_codes.dart';
import '../policies/payments_permission_policy.dart';
import '../repositories/payments_repository.dart';
import '../services/payment_amount_parser.dart';
import '../services/payment_balance_calculator.dart';
import 'payment_params.dart';

final class GetPaymentsUseCase
    implements UseCase<List<Payment>, GetPaymentsParams> {
  final PaymentsRepository _repository;

  const GetPaymentsUseCase(this._repository);

  @override
  Future<Result<List<Payment>>> call(GetPaymentsParams params) {
    final context = params.currentCompanyContext;
    if (!PaymentsPermissionPolicy.canViewPayments(context.role)) {
      return Future.value(
        const FailureResult<List<Payment>>(
          PermissionFailure(code: PaymentFailureCodes.permissionView),
        ),
      );
    }

    return _repository.getPayments(companyId: context.companyId);
  }
}

final class GetPayableInvoicesUseCase
    implements UseCase<List<PayableInvoice>, GetPayableInvoicesParams> {
  final InvoicesRepository _invoicesRepository;
  final PaymentsRepository _paymentsRepository;
  final PaymentBalanceCalculator _balanceCalculator;

  const GetPayableInvoicesUseCase({
    required InvoicesRepository invoicesRepository,
    required PaymentsRepository paymentsRepository,
    PaymentBalanceCalculator balanceCalculator =
        const PaymentBalanceCalculator(),
  }) : _invoicesRepository = invoicesRepository,
       _paymentsRepository = paymentsRepository,
       _balanceCalculator = balanceCalculator;

  @override
  Future<Result<List<PayableInvoice>>> call(
    GetPayableInvoicesParams params,
  ) async {
    final context = params.currentCompanyContext;
    if (!PaymentsPermissionPolicy.canViewPayments(context.role)) {
      return const FailureResult<List<PayableInvoice>>(
        PermissionFailure(code: PaymentFailureCodes.permissionView),
      );
    }

    final invoicesResult = await _invoicesRepository.getInvoices(
      companyId: context.companyId,
    );
    if (invoicesResult is FailureResult<List<Invoice>>) {
      return FailureResult<List<PayableInvoice>>(invoicesResult.failure);
    }

    final paymentsResult = await _paymentsRepository.getPayments(
      companyId: context.companyId,
    );
    if (paymentsResult is FailureResult<List<Payment>>) {
      return FailureResult<List<PayableInvoice>>(paymentsResult.failure);
    }

    final invoices = (invoicesResult as Success<List<Invoice>>).data;
    final payments = (paymentsResult as Success<List<Payment>>).data;
    final payableInvoices = <PayableInvoice>[];

    for (final invoice in invoices) {
      if (!_isPayableStatus(invoice.status)) continue;

      final balanceResult = _balanceCalculator.calculate(
        invoice: invoice,
        payments: payments.where((payment) => payment.invoiceId == invoice.id),
      );
      if (balanceResult is FailureResult<PaymentBalance>) {
        return FailureResult<List<PayableInvoice>>(balanceResult.failure);
      }

      final balance = (balanceResult as Success<PaymentBalance>).data;
      if (balance.remaining.isPositive) {
        payableInvoices.add(PayableInvoice(invoice: invoice, balance: balance));
      }
    }

    return Success<List<PayableInvoice>>(List.unmodifiable(payableInvoices));
  }

  bool _isPayableStatus(InvoiceStatus status) {
    return status == InvoiceStatus.issued ||
        status == InvoiceStatus.partiallyPaid;
  }
}

final class GetPaymentBusinessDateUseCase
    implements UseCase<DateTime, GetPaymentBusinessDateParams> {
  final CompanyBusinessDateProvider _businessDateProvider;

  const GetPaymentBusinessDateUseCase(this._businessDateProvider);

  @override
  Future<Result<DateTime>> call(GetPaymentBusinessDateParams params) {
    final context = params.currentCompanyContext;
    if (!PaymentsPermissionPolicy.canRegisterPayments(context.role)) {
      return Future.value(
        const FailureResult<DateTime>(
          PermissionFailure(code: PaymentFailureCodes.permissionManage),
        ),
      );
    }

    return _businessDateProvider.getBusinessDate(companyId: context.companyId);
  }
}

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
        ValidationFailure(code: PaymentFailureCodes.validationInvoiceIdRequired),
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
        ConflictFailure(
          code: PaymentFailureCodes.conflictInvoiceStatusInvalid,
        ),
      );
    }

    final fractionDigits = context.company.baseCurrencyFractionDigits;
    final baseCurrency = CurrencyCode.tryParse(
      context.company.baseCurrencyCode ?? '',
    );
    if (fractionDigits == null || baseCurrency == null) {
      return const FailureResult<Payment>(
        ConflictFailure(
          code: CompanyFailureCodes.conflictRegionalSettingsNotConfigured,
        ),
      );
    }
    if (invoice.currency != baseCurrency) {
      return const FailureResult<Payment>(
        ValidationFailure(
          code: PaymentFailureCodes.validationCurrencyMismatch,
        ),
      );
    }

    final amount = PaymentAmountParser.tryParse(
      rawValue: params.amountText,
      currency: invoice.currency,
      fractionDigits: fractionDigits,
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

    final paymentDate = _dateOnly(params.paymentDate);
    if (paymentDate.isBefore(_dateOnly(issueDate))) {
      return const FailureResult<Payment>(
        ValidationFailure(
          code: PaymentFailureCodes.validationDateBeforeInvoice,
        ),
      );
    }

    final businessDateResult = await _businessDateProvider.getBusinessDate(
      companyId: context.companyId,
    );
    if (businessDateResult is FailureResult<DateTime>) {
      return FailureResult<Payment>(businessDateResult.failure);
    }
    final businessDate = _dateOnly(
      (businessDateResult as Success<DateTime>).data,
    );
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

DateTime _dateOnly(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}
