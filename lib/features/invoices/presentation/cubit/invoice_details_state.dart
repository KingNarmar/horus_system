import '../../../../core/errors/failure.dart';
import '../../../audit/domain/entities/audit_log.dart';
import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/policies/invoice_lifecycle_policy.dart';
import '../../domain/policies/invoices_permission_policy.dart';

const Object _notSet = Object();

enum InvoiceDetailsAction { issue, cancel }

enum InvoiceDetailsFeedback { issued, cancelled }

sealed class InvoiceDetailsState {
  const InvoiceDetailsState();
}

final class InvoiceDetailsInitial extends InvoiceDetailsState {
  const InvoiceDetailsInitial();
}

final class InvoiceDetailsLoading extends InvoiceDetailsState {
  const InvoiceDetailsLoading();
}

final class InvoiceDetailsLoaded extends InvoiceDetailsState {
  final CurrentCompanyContext currentCompanyContext;
  final Invoice invoice;
  final List<AuditLog> activity;
  final bool isActivityLoading;
  final Failure? activityFailure;
  final InvoiceDetailsAction? pendingAction;
  final Failure? mutationFailure;
  final InvoiceDetailsFeedback? feedback;

  const InvoiceDetailsLoaded({
    required this.currentCompanyContext,
    required this.invoice,
    this.activity = const [],
    this.isActivityLoading = false,
    this.activityFailure,
    this.pendingAction,
    this.mutationFailure,
    this.feedback,
  });

  bool get canEdit {
    return InvoicesPermissionPolicy.canManageInvoiceDrafts(
          currentCompanyContext.role,
        ) &&
        InvoiceLifecyclePolicy.canEdit(invoice.status);
  }

  bool get canIssue {
    return InvoicesPermissionPolicy.canIssueInvoices(
          currentCompanyContext.role,
        ) &&
        InvoiceLifecyclePolicy.canIssue(invoice.status);
  }

  bool get canCancel {
    return InvoicesPermissionPolicy.canCancelInvoices(
          currentCompanyContext.role,
        ) &&
        InvoiceLifecyclePolicy.canCancel(invoice.status);
  }

  bool get isMutationPending => pendingAction != null;

  InvoiceDetailsLoaded copyWith({
    Invoice? invoice,
    List<AuditLog>? activity,
    bool? isActivityLoading,
    Object? activityFailure = _notSet,
    Object? pendingAction = _notSet,
    Object? mutationFailure = _notSet,
    Object? feedback = _notSet,
  }) {
    return InvoiceDetailsLoaded(
      currentCompanyContext: currentCompanyContext,
      invoice: invoice ?? this.invoice,
      activity: activity ?? this.activity,
      isActivityLoading: isActivityLoading ?? this.isActivityLoading,
      activityFailure: activityFailure == _notSet
          ? this.activityFailure
          : activityFailure as Failure?,
      pendingAction: pendingAction == _notSet
          ? this.pendingAction
          : pendingAction as InvoiceDetailsAction?,
      mutationFailure: mutationFailure == _notSet
          ? this.mutationFailure
          : mutationFailure as Failure?,
      feedback: feedback == _notSet
          ? this.feedback
          : feedback as InvoiceDetailsFeedback?,
    );
  }
}

final class InvoiceDetailsFailure extends InvoiceDetailsState {
  final Failure failure;

  const InvoiceDetailsFailure(this.failure);
}
