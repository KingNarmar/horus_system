import '../../../company/domain/entities/current_company_context.dart';
import '../../domain/entities/billable_trip.dart';
import '../../domain/entities/invoice.dart';
import '../../domain/usecases/invoice_params.dart';

final class InvoiceDraftFormInput {
  final String customerId;
  final List<String> tripIds;
  final String currencyCode;
  final int discountMinorUnits;
  final int taxRateBasisPoints;
  final DateTime? issueDate;
  final DateTime? dueDate;
  final String? notes;

  InvoiceDraftFormInput({
    required this.customerId,
    required List<String> tripIds,
    required this.currencyCode,
    this.discountMinorUnits = 0,
    this.taxRateBasisPoints = 0,
    this.issueDate,
    this.dueDate,
    this.notes,
  }) : tripIds = List.unmodifiable(tripIds);

  factory InvoiceDraftFormInput.fromBillableTrip(
    BillableTrip trip, {
    int discountMinorUnits = 0,
    int taxRateBasisPoints = 0,
    DateTime? issueDate,
    DateTime? dueDate,
    String? notes,
  }) {
    return InvoiceDraftFormInput(
      customerId: trip.customerId,
      tripIds: [trip.id],
      currencyCode: trip.freightAmount.currency.value,
      discountMinorUnits: discountMinorUnits,
      taxRateBasisPoints: taxRateBasisPoints,
      issueDate: issueDate,
      dueDate: dueDate,
      notes: notes,
    );
  }

  factory InvoiceDraftFormInput.fromInvoice(Invoice invoice) {
    return InvoiceDraftFormInput(
      customerId: invoice.customer.customerId,
      tripIds: invoice.lines.map((line) => line.tripId).toList(growable: false),
      currencyCode: invoice.currency.value,
      discountMinorUnits: invoice.totals.discount.minorUnits,
      taxRateBasisPoints: invoice.totals.taxRate.basisPoints,
      issueDate: invoice.issueDate?.value,
      dueDate: invoice.dueDate?.value,
      notes: invoice.notes,
    );
  }

  CreateInvoiceFromTripParams toCreateFromTripParams(
    CurrentCompanyContext currentCompanyContext,
  ) {
    return CreateInvoiceFromTripParams(
      currentCompanyContext: currentCompanyContext,
      input: _toDomainInput(),
    );
  }

  UpdateInvoiceDraftParams toUpdateParams({
    required CurrentCompanyContext currentCompanyContext,
    required String invoiceId,
  }) {
    return UpdateInvoiceDraftParams(
      currentCompanyContext: currentCompanyContext,
      invoiceId: invoiceId,
      input: _toDomainInput(),
    );
  }

  InvoiceDraftInput _toDomainInput() {
    return InvoiceDraftInput(
      customerId: customerId,
      tripIds: tripIds,
      currencyCode: currencyCode,
      discountMinorUnits: discountMinorUnits,
      taxRateBasisPoints: taxRateBasisPoints,
      issueDate: issueDate,
      dueDate: dueDate,
      notes: notes,
    );
  }
}
