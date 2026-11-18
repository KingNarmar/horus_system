/// Render-only, locale-resolved labels supplied by Presentation.
/// The PDF service never imports localization or hardcodes visible text.
final class InvoicePdfLabels {
  final bool isRtl;
  final String title;
  final String statusDraft;
  final String statusIssued;
  final String statusPartiallyPaid;
  final String statusPaid;
  final String statusCancelled;
  final String issuer;
  final String customer;
  final String taxRegistration;
  final String invoiceNumber;
  final String issueDate;
  final String dueDate;
  final String trip;
  final String serviceDate;
  final String route;
  final String quantity;
  final String amount;
  final String subtotal;
  final String discount;
  final String taxableAmount;
  final String tax;
  final String total;
  final String notes;
  final String page;
  final String unavailable;
  final String legacyIdentityNotice;

  const InvoicePdfLabels({
    required this.isRtl,
    required this.title,
    required this.statusDraft,
    required this.statusIssued,
    required this.statusPartiallyPaid,
    required this.statusPaid,
    required this.statusCancelled,
    required this.issuer,
    required this.customer,
    required this.taxRegistration,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.trip,
    required this.serviceDate,
    required this.route,
    required this.quantity,
    required this.amount,
    required this.subtotal,
    required this.discount,
    required this.taxableAmount,
    required this.tax,
    required this.total,
    required this.notes,
    required this.page,
    required this.unavailable,
    required this.legacyIdentityNotice,
  });
}
