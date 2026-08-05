import '../value_objects/invoice_date.dart';

abstract interface class InvoiceClock {
  InvoiceDate today();
}
