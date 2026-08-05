import '../entities/invoice_status.dart';

abstract final class InvoiceLifecyclePolicy {
  static bool canEdit(InvoiceStatus status) {
    return status == InvoiceStatus.draft;
  }

  static bool canIssue(InvoiceStatus status) {
    return status == InvoiceStatus.draft;
  }

  static bool canCancel(InvoiceStatus status) {
    return status == InvoiceStatus.draft || status == InvoiceStatus.issued;
  }
}
