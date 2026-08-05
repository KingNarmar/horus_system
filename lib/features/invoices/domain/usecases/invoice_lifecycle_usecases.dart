import '../../../../core/errors/common_failures.dart';
import '../../../../core/errors/failure_codes.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/result.dart';
import '../../../company/domain/entities/company_role.dart';
import '../entities/invoice.dart';
import '../entities/invoice_creation_context.dart';
import '../policies/invoice_lifecycle_policy.dart';
import '../policies/invoices_permission_policy.dart';
import '../repositories/invoices_repository.dart';
import '../services/invoice_clock.dart';
import '../services/invoice_issuance_validator.dart';
import '../value_objects/invoice_date.dart';
import 'invoice_params.dart';

final class IssueInvoiceUseCase
    implements UseCase<Invoice, IssueInvoiceParams> {
  final InvoicesRepository _repository;
  final InvoiceClock _clock;
  final InvoiceIssuanceValidator _issuanceValidator;

  const IssueInvoiceUseCase(
    this._repository, {
    required InvoiceClock clock,
    InvoiceIssuanceValidator issuanceValidator =
        const InvoiceIssuanceValidator(),
  }) : _clock = clock,
       _issuanceValidator = issuanceValidator;

  @override
  Future<Result<Invoice>> call(IssueInvoiceParams params) async {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canIssueInvoices(context.role)) {
      return const FailureResult<Invoice>(
        PermissionFailure(code: FailureCodes.permissionInvoicesIssue),
      );
    }

    final invoiceId = _optional(params.invoiceId);
    if (invoiceId == null) {
      return const FailureResult<Invoice>(
        ValidationFailure(code: FailureCodes.validationInvoiceIdRequired),
      );
    }

    final issueDate = InvoiceDate.fromDateTime(params.issueDate);
    final dueDate = InvoiceDate.fromDateTime(params.dueDate);
    if (issueDate.isAfter(_clock.today())) {
      return const FailureResult<Invoice>(
        ValidationFailure(code: FailureCodes.validationInvoiceIssueDateFuture),
      );
    }
    if (dueDate.isBefore(issueDate)) {
      return const FailureResult<Invoice>(
        ValidationFailure(
          code: FailureCodes.validationInvoiceDueDateBeforeIssue,
        ),
      );
    }

    final currentResult = await _repository.getInvoiceDetails(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
    if (currentResult is FailureResult<Invoice>) {
      return FailureResult<Invoice>(currentResult.failure);
    }

    final invoice = (currentResult as Success<Invoice>).data;
    if (!InvoiceLifecyclePolicy.canIssue(invoice.status)) {
      return const FailureResult<Invoice>(
        ConflictFailure(
          code: FailureCodes.conflictInvoiceStatusTransitionInvalid,
        ),
      );
    }

    final contextResult = await _repository.getCreationContext(
      companyId: context.companyId,
      tripIds: invoice.lines.map((line) => line.tripId).toList(growable: false),
    );
    if (contextResult is FailureResult<InvoiceCreationContext>) {
      return FailureResult<Invoice>(contextResult.failure);
    }

    final validationFailure = _issuanceValidator.validate(
      invoice: invoice,
      context: (contextResult as Success<InvoiceCreationContext>).data,
    );
    if (validationFailure != null) {
      return FailureResult<Invoice>(validationFailure);
    }

    return _repository.issueInvoice(
      companyId: context.companyId,
      invoiceId: invoiceId,
      issueDate: issueDate,
      dueDate: dueDate,
      actorRole: context.role.value,
    );
  }
}

final class CancelInvoiceUseCase
    implements UseCase<Invoice, CancelInvoiceParams> {
  final InvoicesRepository _repository;

  const CancelInvoiceUseCase(this._repository);

  @override
  Future<Result<Invoice>> call(CancelInvoiceParams params) async {
    final context = params.currentCompanyContext;
    if (!InvoicesPermissionPolicy.canCancelInvoices(context.role)) {
      return const FailureResult<Invoice>(
        PermissionFailure(code: FailureCodes.permissionInvoicesCancel),
      );
    }

    final invoiceId = _optional(params.invoiceId);
    if (invoiceId == null) {
      return const FailureResult<Invoice>(
        ValidationFailure(code: FailureCodes.validationInvoiceIdRequired),
      );
    }

    final reason = _optional(params.reason);
    if (reason == null) {
      return const FailureResult<Invoice>(
        ValidationFailure(
          code: FailureCodes.validationInvoiceCancellationReasonRequired,
        ),
      );
    }

    final currentResult = await _repository.getInvoiceDetails(
      companyId: context.companyId,
      invoiceId: invoiceId,
    );
    if (currentResult is FailureResult<Invoice>) {
      return FailureResult<Invoice>(currentResult.failure);
    }

    final invoice = (currentResult as Success<Invoice>).data;
    if (!InvoiceLifecyclePolicy.canCancel(invoice.status)) {
      return const FailureResult<Invoice>(
        ConflictFailure(
          code: FailureCodes.conflictInvoiceStatusTransitionInvalid,
        ),
      );
    }

    return _repository.cancelInvoice(
      companyId: context.companyId,
      invoiceId: invoiceId,
      reason: reason,
      actorRole: context.role.value,
    );
  }
}

String? _optional(String? value) {
  final normalized = value?.trim();
  if (normalized == null || normalized.isEmpty) return null;
  return normalized;
}
