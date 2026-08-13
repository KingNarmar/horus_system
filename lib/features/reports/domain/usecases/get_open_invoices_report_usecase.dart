import '../../../../core/domain/value_objects/money.dart';
import '../../../../core/errors/common_failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../invoices/domain/entities/invoice_status.dart';
import '../../../payments/domain/entities/payment_balance.dart';
import '../entities/open_invoices_report.dart';
import '../failures/reports_failure_codes.dart';
import '../policies/reports_permission_policy.dart';
import '../repositories/reports_repository.dart';
import '../services/open_invoice_balance_resolver.dart';
import '../services/report_source_integrity.dart';
import '../services/reports_context_validator.dart';
import 'report_params.dart';

final class GetOpenInvoicesReportUseCase
    implements UseCase<OpenInvoicesReport, ReportParams> {
  final ReportsRepository _repository;
  final OpenInvoiceBalanceResolver _balanceResolver;

  const GetOpenInvoicesReportUseCase({
    required ReportsRepository repository,
    OpenInvoiceBalanceResolver balanceResolver =
        const OpenInvoiceBalanceResolver(),
  }) : _repository = repository,
       _balanceResolver = balanceResolver;

  @override
  Future<Result<OpenInvoicesReport>> call(ReportParams params) async {
    final context = params.currentCompanyContext;
    if (!ReportsPermissionPolicy.canViewOpenInvoicesReport(context.role)) {
      return const FailureResult(
        PermissionFailure(
          code: ReportsFailureCodes.permissionOpenInvoicesView,
        ),
      );
    }

    final dateFailure = ReportsContextValidator.validateDateRange(
      params.dateRange,
    );
    if (dateFailure != null) return FailureResult(dateFailure);

    final request = ReportsContextValidator.tryBuild(
      context: context,
      range: params.dateRange,
    );
    if (request == null) {
      return FailureResult(ReportsContextValidator.regionalSettingsFailure());
    }

    final result = await _repository.getOpenInvoicesSource(
      companyId: request.companyId,
      fromDate: request.fromDate,
      toDate: request.toDate,
    );
    if (result is FailureResult<OpenInvoicesReportSource>) {
      return FailureResult(result.failure);
    }

    final source = (result as Success<OpenInvoicesReportSource>).data;
    final metadataFailure = ReportSourceIntegrity.validateMetadata(
      metadata: source.metadata,
      expectedCompanyId: request.companyId,
      expectedCurrency: request.currency,
      expectedFractionDigits: request.fractionDigits,
      expectedBusinessTimezone: request.businessTimezone,
      expectedFromDate: request.fromDate,
      expectedToDate: request.toDate,
    );
    if (metadataFailure != null) return FailureResult(metadataFailure);

    if (ReportSourceIntegrity.hasInvalidCounter([
          source.invoiceCurrencyMismatchCount,
          source.paymentCurrencyMismatchCount,
          source.invalidInvoiceAmountCount,
          source.invalidPaymentAmountCount,
          source.missingIssueDateCount,
        ]) ||
        source.invoiceCurrencyMismatchCount > 0 ||
        source.paymentCurrencyMismatchCount > 0 ||
        source.invalidInvoiceAmountCount > 0 ||
        source.invalidPaymentAmountCount > 0 ||
        source.missingIssueDateCount > 0) {
      return const FailureResult(
        ConflictFailure(
          code: ReportsFailureCodes.conflictFinancialDataInvalid,
        ),
      );
    }

    final invoiceIds = <String>{};
    for (final invoice in source.invoices) {
      if (invoice.invoiceId.trim().isEmpty ||
          !invoiceIds.add(invoice.invoiceId) ||
          invoice.customerId.trim().isEmpty ||
          invoice.customerName.trim().isEmpty ||
          !_isSourceStatus(invoice.status)) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
        );
      }
      if (invoice.total.currency != request.currency) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictCurrencyMismatch),
        );
      }
      if (invoice.total.isNegative) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
    }

    final paymentIds = <String>{};
    final paymentsByInvoice = <String, List<OpenInvoiceSourcePayment>>{};
    for (final payment in source.payments) {
      if (payment.paymentId.trim().isEmpty ||
          !paymentIds.add(payment.paymentId) ||
          !invoiceIds.contains(payment.invoiceId)) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictSourceInvalid),
        );
      }
      if (payment.amount.currency != request.currency) {
        return const FailureResult(
          ConflictFailure(code: ReportsFailureCodes.conflictCurrencyMismatch),
        );
      }
      if (!payment.amount.isPositive) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictFinancialDataInvalid,
          ),
        );
      }
      (paymentsByInvoice[payment.invoiceId] ??= <OpenInvoiceSourcePayment>[])
          .add(payment);
    }

    var totalOutstanding = Money(minorUnits: 0, currency: request.currency);
    final rows = <OpenInvoiceReportRow>[];
    for (final invoice in source.invoices) {
      final balanceResult = _balanceResolver.calculate(
        companyId: request.companyId,
        invoice: invoice,
        payments: paymentsByInvoice[invoice.invoiceId] ??
            const <OpenInvoiceSourcePayment>[],
      );
      if (balanceResult is FailureResult<PaymentBalance>) {
        return const FailureResult(
          ConflictFailure(
            code: ReportsFailureCodes.conflictInvoiceBalanceInvalid,
          ),
        );
      }
      final balance = (balanceResult as Success<PaymentBalance>).data;
      if ((invoice.status == InvoiceStatus.issued ||
              invoice.status == InvoiceStatus.partiallyPaid) &&
          balance.remaining.isPositive) {
        rows.add(
          OpenInvoiceReportRow(
            invoice: invoice,
            paid: balance.paid,
            remaining: balance.remaining,
          ),
        );
        totalOutstanding = totalOutstanding.add(balance.remaining);
      }
    }

    return Success(
      OpenInvoicesReport(
        metadata: source.metadata,
        rows: rows,
        totalOutstanding: totalOutstanding,
      ),
    );
  }

  bool _isSourceStatus(InvoiceStatus status) {
    return status == InvoiceStatus.issued ||
        status == InvoiceStatus.partiallyPaid ||
        status == InvoiceStatus.paid;
  }
}
