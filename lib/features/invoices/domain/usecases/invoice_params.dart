import '../../../company/domain/entities/current_company_context.dart';

final class GetInvoicesParams {
  final CurrentCompanyContext currentCompanyContext;

  const GetInvoicesParams({required this.currentCompanyContext});
}

final class GetInvoiceDetailsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;

  const GetInvoiceDetailsParams({
    required this.currentCompanyContext,
    required this.invoiceId,
  });
}

final class GetBillableTripsParams {
  final CurrentCompanyContext currentCompanyContext;
  final String? customerId;

  const GetBillableTripsParams({
    required this.currentCompanyContext,
    this.customerId,
  });
}

final class InvoiceDraftInput {
  final String customerId;
  final List<String> tripIds;
  final String currencyCode;
  final int discountMinorUnits;
  final int taxRateBasisPoints;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;

  InvoiceDraftInput({
    required this.customerId,
    required List<String> tripIds,
    required this.currencyCode,
    this.discountMinorUnits = 0,
    this.taxRateBasisPoints = 0,
    this.issueDate,
    this.dueDate,
    this.notes,
  }) : tripIds = List.unmodifiable(tripIds);
}

final class CreateInvoiceFromTripParams {
  final CurrentCompanyContext currentCompanyContext;
  final InvoiceDraftInput input;

  const CreateInvoiceFromTripParams({
    required this.currentCompanyContext,
    required this.input,
  });
}

final class CreateGroupedInvoiceParams {
  final CurrentCompanyContext currentCompanyContext;
  final InvoiceDraftInput input;

  const CreateGroupedInvoiceParams({
    required this.currentCompanyContext,
    required this.input,
  });
}

final class UpdateInvoiceDraftParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;
  final InvoiceDraftInput input;

  const UpdateInvoiceDraftParams({
    required this.currentCompanyContext,
    required this.invoiceId,
    required this.input,
  });
}

final class IssueInvoiceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;
  final DateTime issueDate;
  final DateTime dueDate;

  const IssueInvoiceParams({
    required this.currentCompanyContext,
    required this.invoiceId,
    required this.issueDate,
    required this.dueDate,
  });
}

final class CancelInvoiceParams {
  final CurrentCompanyContext currentCompanyContext;
  final String invoiceId;
  final String reason;

  const CancelInvoiceParams({
    required this.currentCompanyContext,
    required this.invoiceId,
    required this.reason,
  });
}
