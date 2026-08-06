import '../../domain/entities/invoice_status.dart';
import 'invoices_localizations.dart';

extension InvoiceStatusLocalizationsX on InvoiceStatus {
  String localizedLabel(InvoicesLocalizations strings) {
    return switch (this) {
      InvoiceStatus.draft => strings.statusDraft,
      InvoiceStatus.issued => strings.statusIssued,
      InvoiceStatus.cancelled => strings.statusCancelled,
    };
  }
}
