import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../invoices/domain/entities/invoice.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../invoices/domain/repositories/invoices_repository.dart';
import '../entities/payable_invoice.dart';
import '../entities/payment.dart';
import '../entities/payment_balance.dart';
import '../failures/payment_failure_codes.dart';
import '../policies/payments_permission_policy.dart';
import '../repositories/payments_repository.dart';
import '../services/payment_balance_calculator.dart';
import 'payment_params.dart';

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
